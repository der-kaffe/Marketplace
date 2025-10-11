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
            if (usuarioReportadoId && usuarioReportadoId === reportanteId) {
                return res.status(400).json({
                    ok: false,
                    message: 'No puedes reportarte a ti mismo',
                });
            }

            // Si se reporta un producto, verificar que existe
            if (productoId) {
                const producto = await prisma.productos.findUnique({
                    where: { id: Number(productoId) },
                });

                if (!producto) {
                    return res.status(404).json({
                        ok: false,
                        message: 'Producto no encontrado',
                    });
                }

                // Validar que no se reporte su propio producto
                if (producto.vendedorId === reportanteId) {
                    return res.status(400).json({
                        ok: false,
                        message: 'No puedes reportar tu propio producto',
                    });
                }
            }

            // Si se reporta un usuario, verificar que existe
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

            // Verificar si ya existe un reporte similar pendiente
            const reporteExistente = await prisma.reportes.findFirst({
                where: {
                    reportanteId,
                    ...(productoId && { productoId: Number(productoId) }),
                    ...(usuarioReportadoId && {
                        usuarioReportadoId: Number(usuarioReportadoId),
                    }),
                    estadoId: 1, // Estado "Pendiente"
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
                    usuarioReportadoId: usuarioReportadoId
                        ? Number(usuarioReportadoId)
                        : null,
                    motivo,
                    estadoId: 1, // Estado "Pendiente" por defecto
                },
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
            });

            // Registrar actividad del usuario
            await prisma.actividadUsuario.create({
                data: {
                    usuarioId: reportanteId,
                    accion: 'REPORTE_CREADO',
                    detalles: `Reportó ${productoId ? 'producto #' + productoId : 'usuario #' + usuarioReportadoId}`,
                },
            });

            res.status(201).json({
                ok: true,
                message: 'Reporte enviado exitosamente',
                reporte: {
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
            res.status(500).json({
                ok: false,
                message: 'Error interno del servidor',
                error:
                    process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
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