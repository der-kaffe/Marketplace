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
            // }            // 4. Crear la transacción pendiente de confirmación del vendedor
            const transaccion = await tx.transacciones.create({
                data: {
                    productoId: productId,
                    compradorId: compradorId,
                    vendedorId: producto.vendedorId, // Obtenido del producto
                    cantidad: quantity, // Guarda la cantidad comprada
                    precioUnitario: producto.precioActual, // Guarda el precio al momento de la compra
                    precioTotal: (producto.precioActual ?? 0) * quantity, // Calcula el total
                    estadoId: ESTADO_PENDIENTE, // Estado inicial
                    // ⚠️ Transacción pendiente - Vendedor debe confirmar manualmente
                    confirmacionVendedor: false, // Vendedor debe confirmar manualmente
                    confirmacionComprador: false, // Comprador debe confirmar recibo después
                }
            });

            return transaccion; // Devuelve la transacción creada
        }); // Fin de prisma.$transaction        // 5. Respuesta exitosa
        res.status(201).json({
            ok: true,
            message: '¡Pedido realizado con éxito! El vendedor debe confirmar tu compra.',
            transaction: {
                id: nuevaTransaccion.id,
                productoId: nuevaTransaccion.productoId,
                cantidad: nuevaTransaccion.cantidad,
                precioTotal: Number(nuevaTransaccion.precioTotal), // Convertir Decimal
                estadoId: nuevaTransaccion.estadoId,
                confirmacionVendedor: nuevaTransaccion.confirmacionVendedor, // false - Pendiente
                confirmacionComprador: nuevaTransaccion.confirmacionComprador, // false
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
                    vendedor: { select: { id: true, nombre: true, usuario: true } }, // Info del vendedor
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
                },                vendedor: {
                    id: p.vendedor.id,
                    nombreCompleto: p.vendedor.nombre || 'Vendedor',
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
                    comprador: { select: { id: true, nombre: true, usuario: true } },
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
                },                comprador: {
                    id: s.comprador.id,
                    nombreCompleto: s.comprador.nombre || 'Comprador',
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

// PATCH /api/transactions/:id/confirm-seller - Vendedor ACEPTA la venta y marca como entregada en un solo paso
router.patch('/:id/confirm-seller', authenticateToken, async (req, res, next) => {
    try {
        const transactionId = parseInt(req.params.id);
        const userId = req.user.userId;

        const updatedTransaction = await prisma.$transaction(async (tx) => {
            // 1. Buscar transacción y verificar permisos
            const transaccion = await tx.transacciones.findUnique({
                where: { id: transactionId },
                include: {
                    producto: { select: { nombre: true } },
                    comprador: { select: { nombre: true, usuario: true } }
                }
            });

            if (!transaccion) {
                throw new AppError('Transacción no encontrada', 'TRANSACTION_NOT_FOUND', 404);
            }
            if (transaccion.vendedorId !== userId) {
                throw new AppError('No tienes permiso para aceptar esta venta', 'FORBIDDEN', 403);
            }
            if (transaccion.confirmacionVendedor) {
                throw new AppError('Esta venta ya fue aceptada', 'ALREADY_ACCEPTED', 400);
            }

            // 2. ✅ Aceptar la venta = marcar confirmacionVendedor (el vendedor está de acuerdo)
            const confirmed = await tx.transacciones.update({
                where: { id: transactionId },
                data: { 
                    confirmacionVendedor: true, // Vendedor acepta y se compromete a entregar
                },
                select: { confirmacionComprador: true, confirmacionVendedor: true }
            });

            // 3. ✅ Verificar si ahora está completada (si comprador ya había confirmado)
            await checkAndUpdateCompletionStatus(transactionId, tx);

            console.log(`✅ Vendedor ${userId} ACEPTÓ la venta de transacción ${transactionId}`);

            return confirmed;
        });

        res.json({
            ok: true,
            message: '¡Venta aceptada! Coordina con el comprador para la entrega.',
            transaction: {
                id: parseInt(req.params.id),
                confirmacionVendedor: updatedTransaction.confirmacionVendedor,
            }
        });

    } catch (error) {
        next(error);
    }
});

// PATCH /api/transactions/:id/reject-seller - Vendedor rechaza/cancela la venta
router.patch('/:id/reject-seller', authenticateToken, async (req, res, next) => {
    try {
        const transactionId = parseInt(req.params.id);
        const userId = req.user.userId;
        const { motivo } = req.body; // Opcional: motivo del rechazo

        await prisma.$transaction(async (tx) => {
            // 1. Buscar transacción y verificar permisos
            const transaccion = await tx.transacciones.findUnique({
                where: { id: transactionId },
                include: {
                    producto: { select: { id: true, nombre: true } }
                }
            });

            if (!transaccion) {
                throw new AppError('Transacción no encontrada', 'TRANSACTION_NOT_FOUND', 404);
            }
            if (transaccion.vendedorId !== userId) {
                throw new AppError('No tienes permiso para rechazar esta venta', 'FORBIDDEN', 403);
            }
            if (transaccion.confirmacionVendedor) {
                throw new AppError('No puedes rechazar una venta ya confirmada', 'ALREADY_CONFIRMED', 400);
            }

            // 2. Devolver el stock al producto ANTES de eliminar la transacción
            await tx.productos.update({
                where: { id: transaccion.productoId },
                data: {
                    cantidad: {
                        increment: transaccion.cantidad
                    }
                }
            });

            // 3. Eliminar la transacción (no existe estado "Cancelado" en la BD)
            await tx.transacciones.delete({
                where: { id: transactionId }
            });

            console.log(`❌ Vendedor ${userId} rechazó la venta de transacción ${transactionId}. Stock devuelto y transacción eliminada.`);
        });

        res.json({
            ok: true,
            message: 'Venta rechazada. El stock ha sido devuelto al producto.',
        });

    } catch (error) {
        next(error);
    }
});

// PATCH /api/transactions/:id/confirm-delivery - Vendedor confirma entrega física
// ℹ️ NOTA: La confirmación inicial se hace automáticamente al crear la transacción.
//          Este endpoint es para confirmar que el producto fue entregado físicamente al comprador.
router.patch('/:id/confirm-delivery', authenticateToken, async (req, res, next) => {
    try {
        const transactionId = parseInt(req.params.id);
        const userId = req.user.userId;

        const updatedTransaction = await prisma.$transaction(async (tx) => {
            // 1. Buscar transacción y verificar permisos
            const transaccion = await tx.transacciones.findUnique({
                where: { id: transactionId },
                select: { vendedorId: true, estadoId: true, confirmacionVendedor: true }
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

            // 2. Marcar confirmación del vendedor (por si acaso no estaba confirmada)
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
            message: 'Entrega física confirmada exitosamente.',
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