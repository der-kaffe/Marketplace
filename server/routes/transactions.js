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
const ESTADO_COMPLETADO = 3; // O el ID que corresponda a "Completado"
const ESTADO_CANCELADO = 4; // O el ID que corresponda a "Cancelado"
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

// --- AQUÍ AÑADIREMOS LAS RUTAS PARA CONFIRMAR VENTA Y RECIBO ---
// PATCH /api/transactions/:id/confirm-delivery (Vendedor)
// PATCH /api/transactions/:id/confirm-receipt (Comprador)
// GET /api/transactions/purchases (Mis Compras)
// GET /api/transactions/sales (Mis Ventas)

module.exports = router;