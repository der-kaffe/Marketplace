// routes/reports.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Util para manejar errores de validación
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            ok: false,
            message: 'Datos de entrada inválidos',
            errors: errors.array(),
        });
    }
    next();
};

// ==========================================
// POST /api/reports - Crear un reporte
// ==========================================
router.post(
    '/',
    authenticateToken,
    [
        body('motivo')
            .isLength({ min: 10 })
            .withMessage('El motivo debe tener al menos 10 caracteres'),
        body('productoId')
            .optional()
            .isInt()
            .withMessage('productoId debe ser un número entero'),
        body('usuarioReportadoId')
            .optional()
            .isInt()
            .withMessage('usuarioReportadoId debe ser un número entero'),
    ],
    handleValidationErrors,
    async (req, res) => {
        try {
            const { motivo, productoId, usuarioReportadoId } = req.body;
            const reportanteId = req.user.userId;

            // Validar que al menos se reporte un producto o usuario
            if (!productoId && !usuarioReportadoId) {
                return res.status(400).json({
                    ok: false,
                    message: 'Debe especificar al menos un productoId o usuarioReportadoId',
                });
            }

            // Validar que no se reporte a sí mismo
            if (usuarioReportadoId && Number(usuarioReportadoId) === reportanteId) { // Convertir a Number para comparación estricta
                return res.status(400).json({
                    ok: false,
                    message: 'No puedes reportarte a ti mismo',
                });
            }

            // Validar existencia del producto
            let productoReportado = null; // Guardamos el producto para usarlo después
            if (productoId) {
                productoReportado = await prisma.productos.findUnique({
                    where: { id: Number(productoId) },
                });

                if (!productoReportado) {
                    return res.status(404).json({
                        ok: false,
                        message: 'Producto no encontrado',
                    });
                }

                if (productoReportado.vendedorId === reportanteId) {
                    return res.status(400).json({
                        ok: false,
                        message: 'No puedes reportar tu propio producto',
                    });
                }
            }

            // Validar existencia del usuario reportado
            if (usuarioReportadoId) {
                const usuario = await prisma.cuentas.findUnique({
                    where: { id: Number(usuarioReportadoId) },
                });

                if (!usuario) {
                    return res.status(404).json({
                        ok: false,
                        message: 'Usuario no encontrado',
                    });
                }
            }

            // Evitar reportes duplicados pendientes
            const reporteExistente = await prisma.reportes.findFirst({
                where: {
                    reportanteId,
                    ...(productoId && { productoId: Number(productoId) }),
                    ...(usuarioReportadoId && { usuarioReportadoId: Number(usuarioReportadoId) }),
                    estadoId: 1, // Pendiente
                },
            });

            if (reporteExistente) {
                return res.status(409).json({
                    ok: false,
                    message: 'Ya has reportado este elemento anteriormente',
                });
            }

            // Crear el reporte
            const nuevoReporte = await prisma.reportes.create({
                data: {
                    reportanteId,
                    productoId: productoId ? Number(productoId) : null,
                    usuarioReportadoId: usuarioReportadoId ? Number(usuarioReportadoId) : null,
                    motivo,
                    estadoId: 1, // Pendiente por defecto
                },
                include: { // Incluimos datos necesarios para la notificación
                    reportante: { select: { id: true, nombre: true, usuario: true } }, // Añadimos 'usuario' si no estaba
                    producto: { select: { id: true, nombre: true, vendedorId: true } },
                    usuarioReportado: { select: { id: true, nombre: true } },
                    estado: true,
                },
            });

            // Registrar actividad del usuario
            await prisma.actividadUsuario.create({
                data: {
                    usuarioId: reportanteId,
                    accion: 'REPORTE_CREADO',
                    detalles: `Reportó ${productoId ? 'producto #' + productoId : 'usuario #' + usuarioReportadoId}`,
                },
            });

            // --- 👇👇👇 INICIO: LÓGICA PARA CREAR NOTIFICACIÓN 👇👇👇 ---
            let recipientId = null;
            let notificationMessage = '';
            const reporterName = nuevoReporte.reportante.usuario || nuevoReporte.reportante.nombre || 'Alguien'; // Usar username, nombre o fallback

            // Determinar quién recibe la notificación
            if (nuevoReporte.usuarioReportadoId) {
                // Notificar al usuario reportado directamente
                recipientId = nuevoReporte.usuarioReportadoId;
                notificationMessage = `${reporterName} ha reportado tu cuenta. Motivo: "${motivo}"`;
                console.log(`🔔 Notificando al usuario ${recipientId} sobre reporte de cuenta.`);

            } else if (nuevoReporte.productoId && productoReportado) { // Usamos la variable guardada
                // Notificar al vendedor del producto reportado
                recipientId = productoReportado.vendedorId;
                // Verificación extra (aunque ya se validó antes)
                if (recipientId !== reportanteId) {
                    notificationMessage = `${reporterName} ha reportado tu producto "${productoReportado.nombre}". Motivo: "${motivo}"`;
                    console.log(`🔔 Notificando al vendedor ${recipientId} sobre reporte del producto ${nuevoReporte.productoId}.`);
                } else {
                    recipientId = null; // No notificar si el vendedor es el mismo reportante
                }
            }


            // Respuesta final al usuario que creó el reporte
            res.status(201).json({
                ok: true,
                message: 'Reporte enviado exitosamente',
                reporte: { // Enviamos datos simplificados
                    id: nuevoReporte.id,
                    motivo: nuevoReporte.motivo,
                    fecha: nuevoReporte.fecha,
                    estado: nuevoReporte.estado.nombre,
                    productoId: nuevoReporte.productoId,
                    usuarioReportadoId: nuevoReporte.usuarioReportadoId,
                },
            });
        } catch (error) {
            console.error('❌ Error creando reporte:', error);
            // Asegurarse de que los errores de validación de Prisma también se manejen bien
            if (error.code === 'P2003' || error.code === 'P2025') { // Foreign key constraint or record not found
                return res.status(400).json({ ok: false, message: 'ID de producto o usuario inválido.' });
            }
            res.status(500).json({ ok: false, message: 'Error interno del servidor' });
        }
    }
);


// ==========================================
// GET /api/reports - Listar reportes (Admin)
// ==========================================
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { page = 1, limit = 20, estado } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const where = {};

        // Filtrar por estado si se proporciona
        if (estado) {
            const estadoObj = await prisma.estadosReporte.findFirst({
                where: { nombre: { equals: estado, mode: 'insensitive' } },
            });

            if (estadoObj) {
                where.estadoId = estadoObj.id;
            }
        }

        const [reportes, total] = await Promise.all([
            prisma.reportes.findMany({
                where,
                include: {
                    reportante: {
                        select: {
                            id: true,
                            nombre: true,
                            apellido: true,
                            correo: true,
                        },
                    },
                    producto: {
                        select: {
                            id: true,
                            nombre: true,
                            vendedorId: true,
                        },
                    },
                    usuarioReportado: {
                        select: {
                            id: true,
                            nombre: true,
                            apellido: true,
                            correo: true,
                        },
                    },
                    estado: true,
                },
                orderBy: { fecha: 'desc' },
                skip,
                take: parseInt(limit),
            }),
            prisma.reportes.count({ where }),
        ]);

        res.json({
            ok: true,
            reportes,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        console.error('❌ Error listando reportes:', error);
        res.status(500).json({
            ok: false,
            message: 'Error interno del servidor',
        });
    }
});

// ==========================================
// GET /api/reports/my-reports - Mis reportes
// ==========================================
router.get('/my-reports', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const reportanteId = req.user.userId;

        const [reportes, total] = await Promise.all([
            prisma.reportes.findMany({
                where: { reportanteId },
                include: {
                    producto: {
                        select: {
                            id: true,
                            nombre: true,
                        },
                    },
                    usuarioReportado: {
                        select: {
                            id: true,
                            nombre: true,
                            apellido: true,
                        },
                    },
                    estado: true,
                },
                orderBy: { fecha: 'desc' },
                skip,
                take: parseInt(limit),
            }),
            prisma.reportes.count({ where: { reportanteId } }),
        ]);

        res.json({
            ok: true,
            reportes,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        console.error('❌ Error obteniendo mis reportes:', error);
        res.status(500).json({
            ok: false,
            message: 'Error interno del servidor',
        });
    }
});

// ==========================================
// PATCH /api/reports/:id - Actualizar estado (Admin)
// ==========================================
router.patch(
    '/:id',
    authenticateToken,
    requireAdmin,
    [
        body('estadoId')
            .isInt({ min: 1 })
            .withMessage('estadoId debe ser un número válido'),
    ],
    handleValidationErrors,
    async (req, res) => {
        try {
            const { id } = req.params;
            const { estadoId } = req.body;

            // Verificar que el reporte existe
            const reporte = await prisma.reportes.findUnique({
                where: { id: Number(id) },
            });

            if (!reporte) {
                return res.status(404).json({
                    ok: false,
                    message: 'Reporte no encontrado',
                });
            }

            // Verificar que el estado existe
            const estado = await prisma.estadosReporte.findUnique({
                where: { id: Number(estadoId) },
            });

            if (!estado) {
                return res.status(400).json({
                    ok: false,
                    message: 'Estado no válido',
                });
            }

            // Actualizar el reporte
            const reporteActualizado = await prisma.reportes.update({
                where: { id: Number(id) },
                data: { estadoId: Number(estadoId) },
                include: {
                    reportante: {
                        select: {
                            id: true,
                            nombre: true,
                            apellido: true,
                        },
                    },
                    producto: {
                        select: {
                            id: true,
                            nombre: true,
                        },
                    },
                    usuarioReportado: {
                        select: {
                            id: true,
                            nombre: true,
                            apellido: true,
                        },
                    },
                    estado: true,
                },
            });

            res.json({
                ok: true,
                message: 'Estado del reporte actualizado',
                reporte: reporteActualizado,
            });
        } catch (error) {
            console.error('❌ Error actualizando reporte:', error);
            res.status(500).json({
                ok: false,
                message: 'Error interno del servidor',
            });
        }
    }
);

// ==========================================
// GET /api/reports/estados - Obtener estados
// ==========================================
router.get('/estados/list', async (req, res) => {
    try {
        const estados = await prisma.estadosReporte.findMany({
            orderBy: { id: 'asc' },
        });

        res.json({
            ok: true,
            estados,
        });
    } catch (error) {
        console.error('❌ Error obteniendo estados de reporte:', error);
        res.status(500).json({
            ok: false,
            message: 'Error interno del servidor',
        });
    }
});

// ==========================================
// GET /api/reports/:id - Detalle de un reporte (Admin)
// ==========================================
router.get('/:id', authenticateToken, requireAdmin, async (req, res) => {
    const { id } = req.params;

    try {
        const reporte = await prisma.reportes.findUnique({
            where: { id: Number(id) },
            include: {
                producto: {
                    select: {
                        id: true,
                        nombre: true,
                        descripcion: true,
                        //imagen: true,
                        vendedorId: true,
                    },
                },
                usuarioReportado: {
                    select: {
                        id: true,
                        nombre: true,
                        apellido: true,
                        correo: true,
                    },
                },
                reportante: {
                    select: {
                        id: true,
                        nombre: true,
                        apellido: true,
                        correo: true,
                    },
                },
                estado: true,
            },
        });

        if (!reporte) {
            return res.status(404).json({
                ok: false,
                message: 'Reporte no encontrado',
            });
        }

        res.json({
            ok: true,
            reporte,
        });
    } catch (error) {
        console.error('❌ Error obteniendo detalle del reporte:', error);
        res.status(500).json({
            ok: false,
            message: 'Error interno del servidor',
        });
    }
});



module.exports = router;