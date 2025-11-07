// server/routes/transactions.js

const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const AppError = require('../utils/AppError'); // Asumiendo que tienes este helper

const router = express.Router();

// --- ESTADOS DE TRANSACCIÓN ---
// Asumimos IDs basados en tu schema.prisma o migration.sql. ¡VERIFICA ESTOS IDs!
const ESTADO_PENDIENTE = 1; // O el ID que corresponda a "Pendiente" o "En Proceso"
const ESTADO_COMPLETADO = 2; // O el ID que corresponda a "Completado"
const ESTADO_CANCELADO = 3; // O el ID que corresponda a "Cancelado"
// Podrías añadir "ENTREGADO_VENDEDOR" y "RECIBIDO_COMPRADOR" si los necesitas

// POST /api/transactions - Iniciar una nueva compra
router.post('/', authenticateToken, [
    // Validación básica de la entrada
    body('productId').isInt({ min: 1 }).withMessage('ID de producto inválido'),
    body('quantity').isInt({ min: 1 }).withMessage('La cantidad debe ser al menos 1')
], async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                ok: false,
                message: 'Datos inválidos',
                errors: errors.array()
            });
        }

        const { productId, quantity } = req.body;
        const compradorId = req.user.userId; // ID del usuario autenticado (comprador)

        // Usamos una transacción de Prisma para asegurar atomicidad
        const nuevaTransaccion = await prisma.$transaction(async (tx) => {
            // 1. Buscar el producto y bloquearlo para evitar condiciones de carrera
            const producto = await tx.productos.findUnique({
                where: { id: productId },
                // Podrías añadir 'forUpdate()' si tu DB lo soporta y quieres más seguridad
            });

            // 2. Validar que el producto existe, está disponible y tiene stock
            if (!producto) {
                throw new AppError('Producto no encontrado', 'PRODUCT_NOT_FOUND', 404);
            }
            if (producto.vendedorId === compradorId) {
                throw new AppError('No puedes comprar tu propio producto', 'SELF_PURCHASE_NOT_ALLOWED', 400);
            }
            if (producto.estadoId !== 1 || !producto.visible) { // Asumiendo estadoId 1 = Disponible
                throw new AppError('Este producto no está disponible para la venta', 'PRODUCT_UNAVAILABLE', 400);
            }
            if (producto.cantidad == null || producto.cantidad < quantity) {
                throw new AppError(`Stock insuficiente. Solo quedan ${producto.cantidad ?? 0} unidades.`, 'INSUFFICIENT_STOCK', 400);
            }

            // 3. Reducir el stock del producto
            const productoActualizado = await tx.productos.update({
                where: { id: productId },
                data: {
                    cantidad: {
                        decrement: quantity
                    }
                }
            });

            // (Opcional: Si la cantidad llega a 0, podrías cambiar el estadoId del producto a "Agotado")
            // if (productoActualizado.cantidad <= 0) {
            //   await tx.productos.update({ where: { id: productId }, data: { estadoId: ID_ESTADO_AGOTADO }});
            // }

            // 4. Crear la transacción
            const transaccion = await tx.transacciones.create({
                data: {
                    productoId: productId,
                    compradorId: compradorId,
                    vendedorId: producto.vendedorId, // Obtenido del producto
                    cantidad: quantity, // Guarda la cantidad comprada
                    precioUnitario: producto.precioActual, // Guarda el precio al momento de la compra
                    precioTotal: (producto.precioActual ?? 0) * quantity, // Calcula el total
                    estadoId: ESTADO_PENDIENTE, // Estado inicial
                    // Nuevos campos para confirmación (AÑADIR AL SCHEMA.PRISMA si no existen)
                    confirmacionVendedor: false,
                    confirmacionComprador: false,
                }
            });

            return transaccion; // Devuelve la transacción creada
        }); // Fin de prisma.$transaction

        // 5. Respuesta exitosa
        res.status(201).json({
            ok: true,
            message: 'Pedido realizado con éxito. Esperando confirmación.',
            transaction: {
                id: nuevaTransaccion.id,
                productoId: nuevaTransaccion.productoId,
                cantidad: nuevaTransaccion.cantidad,
                precioTotal: Number(nuevaTransaccion.precioTotal), // Convertir Decimal
                estadoId: nuevaTransaccion.estadoId,
                fecha: nuevaTransaccion.fechaTransaccion // O el nombre real del campo de fecha
            }
        });

    } catch (error) {
        next(error); // Pasa al manejador de errores global
    }
});

// --- RUTAS PARA VER TRANSACCIONES ---

// GET /api/transactions/purchases - Listar compras del usuario actual
router.get('/purchases', authenticateToken, async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const { page = 1, limit = 10 } = req.query; // Paginación opcional

        const currentPage = Math.max(1, parseInt(page));
        const currentLimit = Math.max(1, parseInt(limit));
        const skip = (currentPage - 1) * currentLimit;

        const [purchases, total] = await prisma.$transaction([
            prisma.transacciones.findMany({
                where: { compradorId: userId },
                include: {
                    producto: { select: { id: true, nombre: true, imagenes: { take: 1, select: { urlImagen: true } } } }, // Incluir info básica del producto e imagen
                    vendedor: { select: { id: true, nombre: true, apellido: true, usuario: true } }, // Info del vendedor
                    estado: { select: { nombre: true } } // Nombre del estado
                },
                orderBy: { fecha: 'desc' },
                skip,
                take: currentLimit,
            }),
            prisma.transacciones.count({ where: { compradorId: userId } })
        ]);

        res.json({
            ok: true,
            purchases: purchases.map(p => ({ // Formatear respuesta
                id: p.id,
                fecha: p.fecha,
                estado: p.estado.nombre,
                cantidad: p.cantidad,
                precioTotal: Number(p.precioTotal),
                confirmacionComprador: p.confirmacionComprador,
                confirmacionVendedor: p.confirmacionVendedor,
                producto: {
                    id: p.producto.id,
                    nombre: p.producto.nombre,
                    // TODO: Manejar URL de imagen si 'imagenes' contiene URLs
                    // imageUrl: p.producto.imagenes.length > 0 ? p.producto.imagenes[0].urlImagen : null
                },
                vendedor: {
                    id: p.vendedor.id,
                    nombreCompleto: `${p.vendedor.nombre || ''} ${p.vendedor.apellido || ''}`.trim(),
                    usuario: p.vendedor.usuario,
                }
            })),
            pagination: {
                page: currentPage,
                limit: currentLimit,
                total,
                totalPages: Math.ceil(total / currentLimit)
            }
        });
    } catch (error) {
        next(error);
    }
});

// GET /api/transactions/sales - Listar ventas del usuario actual
router.get('/sales', authenticateToken, async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const { page = 1, limit = 10 } = req.query;

        const currentPage = Math.max(1, parseInt(page));
        const currentLimit = Math.max(1, parseInt(limit));
        const skip = (currentPage - 1) * currentLimit;

        const [sales, total] = await prisma.$transaction([
            prisma.transacciones.findMany({
                where: { vendedorId: userId },
                include: {
                    producto: { select: { id: true, nombre: true, imagenes: { take: 1, select: { urlImagen: true } } } },
                    comprador: { select: { id: true, nombre: true, apellido: true, usuario: true } },
                    estado: { select: { nombre: true } }
                },
                orderBy: { fecha: 'desc' },
                skip,
                take: currentLimit,
            }),
            prisma.transacciones.count({ where: { vendedorId: userId } })
        ]);

         res.json({
            ok: true,
            sales: sales.map(s => ({ // Formatear respuesta
                id: s.id,
                fecha: s.fecha,
                estado: s.estado.nombre,
                cantidad: s.cantidad,
                precioTotal: Number(s.precioTotal),
                confirmacionComprador: s.confirmacionComprador,
                confirmacionVendedor: s.confirmacionVendedor,
                producto: {
                    id: s.producto.id,
                    nombre: s.producto.nombre,
                    // imageUrl: s.producto.imagenes.length > 0 ? s.producto.imagenes[0].urlImagen : null
                },
                comprador: {
                    id: s.comprador.id,
                    nombreCompleto: `${s.comprador.nombre || ''} ${s.comprador.apellido || ''}`.trim(),
                    usuario: s.comprador.usuario,
                }
            })),
            pagination: {
                page: currentPage,
                limit: currentLimit,
                total,
                totalPages: Math.ceil(total / currentLimit)
            }
        });
    } catch (error) {
        next(error);
    }
});


// --- RUTAS PARA CONFIRMACIÓN ---

// Función helper para verificar y actualizar estado si ambos confirman
async function checkAndUpdateCompletionStatus(transactionId, tx) {
    const currentTransaction = await tx.transacciones.findUnique({
        where: { id: transactionId },
        select: { confirmacionVendedor: true, confirmacionComprador: true, estadoId: true }
    });

    if (currentTransaction && currentTransaction.confirmacionVendedor && currentTransaction.confirmacionComprador && currentTransaction.estadoId !== ESTADO_COMPLETADO) {
        console.log(`✅ Transacción ${transactionId}: Ambas partes confirmaron. Marcando como Completada.`);
        return tx.transacciones.update({
            where: { id: transactionId },
            data: { estadoId: ESTADO_COMPLETADO }
        });
    }
    return null; // No necesita actualización de estado
}

// PATCH /api/transactions/:id/confirm-delivery - Vendedor confirma entrega
router.patch('/:id/confirm-delivery', authenticateToken, async (req, res, next) => {
    try {
        const transactionId = parseInt(req.params.id);
        const userId = req.user.userId;

        const updatedTransaction = await prisma.$transaction(async (tx) => {
            // 1. Buscar transacción y verificar permisos
            const transaccion = await tx.transacciones.findUnique({
                where: { id: transactionId },
                select: { vendedorId: true, estadoId: true }
            });

            if (!transaccion) {
                throw new AppError('Transacción no encontrada', 'TRANSACTION_NOT_FOUND', 404);
            }
            if (transaccion.vendedorId !== userId) {
                throw new AppError('No tienes permiso para confirmar esta entrega', 'FORBIDDEN', 403);
            }
            if (transaccion.estadoId === ESTADO_COMPLETADO || transaccion.estadoId === ESTADO_CANCELADO) {
                 throw new AppError('Esta transacción ya está finalizada o cancelada', 'TRANSACTION_FINALIZED', 400);
            }

            // 2. Marcar confirmación del vendedor
            const confirmed = await tx.transacciones.update({
                where: { id: transactionId },
                data: { confirmacionVendedor: true },
                select: { confirmacionComprador: true } // Necesitamos saber si el comprador ya confirmó
            });

            // 3. Verificar si ahora está completada y actualizar estado si es necesario
            await checkAndUpdateCompletionStatus(transactionId, tx);

            return confirmed; // Devolvemos el estado de confirmación del comprador
        });

        res.json({
            ok: true,
            message: 'Entrega confirmada.',
            // Opcional: devolver el estado actual para que la UI sepa si se completó
            // isCompleted: updatedTransaction.confirmacionComprador // Si el comprador ya había confirmado
        });

    } catch (error) {
        next(error);
    }
});

// PATCH /api/transactions/:id/confirm-receipt - Comprador confirma recibo
router.patch('/:id/confirm-receipt', authenticateToken, async (req, res, next) => {
    try {
        const transactionId = parseInt(req.params.id);
        const userId = req.user.userId;

         const updatedTransaction = await prisma.$transaction(async (tx) => {
            // 1. Buscar transacción y verificar permisos
            const transaccion = await tx.transacciones.findUnique({
                where: { id: transactionId },
                select: { compradorId: true, estadoId: true }
            });

            if (!transaccion) {
                throw new AppError('Transacción no encontrada', 'TRANSACTION_NOT_FOUND', 404);
            }
            if (transaccion.compradorId !== userId) {
                throw new AppError('No tienes permiso para confirmar este recibo', 'FORBIDDEN', 403);
            }
             if (transaccion.estadoId === ESTADO_COMPLETADO || transaccion.estadoId === ESTADO_CANCELADO) {
                 throw new AppError('Esta transacción ya está finalizada o cancelada', 'TRANSACTION_FINALIZED', 400);
            }

            // 2. Marcar confirmación del comprador
            const confirmed = await tx.transacciones.update({
                where: { id: transactionId },
                data: { confirmacionComprador: true },
                select: { confirmacionVendedor: true } // Necesitamos saber si el vendedor ya confirmó
            });

            // 3. Verificar si ahora está completada y actualizar estado si es necesario
            await checkAndUpdateCompletionStatus(transactionId, tx);

            return confirmed;
        });

        res.json({
            ok: true,
            message: 'Recibo confirmado.',
            // isCompleted: updatedTransaction.confirmacionVendedor
        });
    } catch (error) {
        next(error);
    }
});

module.exports = router;