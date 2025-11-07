const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/sales - Obtener todas las ventas del vendedor autenticado
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, estado } = req.query;
    
    const currentPage = Math.max(1, parseInt(page));
    const currentLimit = Math.max(1, Math.min(100, parseInt(limit)));
    const skip = (currentPage - 1) * currentLimit;

    // ✅ Construir filtro
    const where = {
      vendedorId: req.user.userId
    };

    // Filtrar por estado si se proporciona
    if (estado) {
      where.estado = {
        nombre: { equals: estado, mode: 'insensitive' }
      };
    }

    // ✅ Obtener ventas del vendedor
    const ventas = await prisma.transacciones.findMany({
      where,
      include: {
        producto: {
          select: {
            id: true,
            nombre: true,
            descripcion: true,
            precioActual: true,
            categoria: {
              select: { nombre: true }
            }
          }
        },
        comprador: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            usuario: true,
            campus: true
          }
        },
        estado: true
      },
      orderBy: {
        fechaTransaccion: 'desc'
      },
      skip,
      take: currentLimit
    });

    // ✅ Obtener total para paginación
    const total = await prisma.transacciones.count({ where });

    // ✅ Calcular estadísticas
    const estadisticas = await prisma.transacciones.aggregate({
      where: { vendedorId: req.user.userId },
      _sum: { precioTotal: true },
      _count: { id: true }
    });

    const ventasPorEstado = await prisma.transacciones.groupBy({
      by: ['estadoId'],
      where: { vendedorId: req.user.userId },
      _count: { id: true }
    });

    res.json({
      ok: true,
      ventas: ventas.map(venta => ({
        id: venta.id,
        fechaTransaccion: venta.fechaTransaccion,
        precioTotal: Number(venta.precioTotal),
        cantidad: venta.cantidad,
        estado: venta.estado.nombre,
        producto: {
          id: venta.producto.id,
          nombre: venta.producto.nombre,
          descripcion: venta.producto.descripcion,
          precioActual: Number(venta.producto.precioActual),
          categoria: venta.producto.categoria?.nombre
        },
        comprador: venta.comprador
      })),
      estadisticas: {
        totalVentas: estadisticas._count.id,
        totalIngresos: Number(estadisticas._sum.precioTotal || 0),
        ventasPorEstado: ventasPorEstado.map(e => ({
          estadoId: e.estadoId,
          cantidad: e._count.id
        }))
      },
      pagination: {
        page: currentPage,
        limit: currentLimit,
        total,
        totalPages: Math.ceil(total / currentLimit)
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo ventas:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/sales/:id - Obtener detalle de una venta específica
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const venta = await prisma.transacciones.findUnique({
      where: { id: parseInt(id) },
      include: {
        producto: {
          include: {
            categoria: true,
            imagenes: true
          }
        },
        comprador: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            usuario: true,
            campus: true,
            telefono: true,
            direccion: true,
            reputacion: true
          }
        },
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            usuario: true
          }
        },
        estado: true
      }
    });

    if (!venta) {
      return res.status(404).json({
        ok: false,
        message: 'Venta no encontrada'
      });
    }

    // ✅ Verificar permisos: solo el vendedor, comprador o admin pueden ver
    if (
      venta.vendedorId !== req.user.userId &&
      venta.compradorId !== req.user.userId &&
      req.user.role !== 'ADMIN'
    ) {
      return res.status(403).json({
        ok: false,
        message: 'No tienes permiso para ver esta venta'
      });
    }

    res.json({
      ok: true,
      venta: {
        id: venta.id,
        fechaTransaccion: venta.fechaTransaccion,
        precioTotal: Number(venta.precioTotal),
        cantidad: venta.cantidad,
        estado: venta.estado.nombre,
        producto: {
          id: venta.producto.id,
          nombre: venta.producto.nombre,
          descripcion: venta.producto.descripcion,
          precioActual: Number(venta.producto.precioActual),
          categoria: venta.producto.categoria?.nombre,
          imagenes: venta.producto.imagenes
        },
        comprador: {
          ...venta.comprador,
          reputacion: Number(venta.comprador.reputacion || 0)
        },
        vendedor: venta.vendedor
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo venta:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/sales/stats/summary - Resumen de ventas para dashboard
router.get('/stats/summary', authenticateToken, async (req, res) => {
  try {
    // Total de ventas
    const totalVentas = await prisma.transacciones.count({
      where: { vendedorId: req.user.userId }
    });

    // Total de ingresos
    const ingresos = await prisma.transacciones.aggregate({
      where: { vendedorId: req.user.userId },
      _sum: { precioTotal: true }
    });

    // Ventas del último mes
    const unMesAtras = new Date();
    unMesAtras.setMonth(unMesAtras.getMonth() - 1);

    const ventasUltimoMes = await prisma.transacciones.count({
      where: {
        vendedorId: req.user.userId,
        fechaTransaccion: {
          gte: unMesAtras
        }
      }
    });

    // Productos más vendidos
    const productosMasVendidos = await prisma.transacciones.groupBy({
      by: ['productoId'],
      where: { vendedorId: req.user.userId },
      _sum: { cantidad: true },
      _count: { id: true },
      orderBy: {
        _sum: { cantidad: 'desc' }
      },
      take: 5
    });

    // Obtener detalles de los productos más vendidos
    const productosIds = productosMasVendidos.map(p => p.productoId);
    const productos = await prisma.productos.findMany({
      where: { id: { in: productosIds } },
      select: { id: true, nombre: true }
    });

    const topProductos = productosMasVendidos.map(pv => {
      const producto = productos.find(p => p.id === pv.productoId);
      return {
        productoId: pv.productoId,
        nombre: producto?.nombre || 'Desconocido',
        cantidadVendida: pv._sum.cantidad,
        numeroVentas: pv._count.id
      };
    });

    res.json({
      ok: true,
      resumen: {
        totalVentas,
        totalIngresos: Number(ingresos._sum.precioTotal || 0),
        ventasUltimoMes,
        productosMasVendidos: topProductos
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo resumen:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/sales - Crear nueva transacción
router.post('/', authenticateToken, [
  body('productoId').isInt({ min: 1 }).withMessage('productoId requerido'),
  body('cantidad').isInt({ min: 1 }).withMessage('cantidad requerida'),
  body('estado')
    .isIn(['iniciada', 'esperando_confirmacion', 'completada', 'cancelada'])
    .withMessage('Estado inválido'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        ok: false,
        message: 'Datos inválidos',
        errors: errors.array()
      });
    }

    const { productoId, cantidad, estado } = req.body;

    // Buscar el producto y su vendedor
    const producto = await prisma.productos.findUnique({
      where: { id: productoId },
      include: { vendedor: true }
    });

    if (!producto) {
      return res.status(404).json({ ok: false, message: 'Producto no encontrado' });
    }

    // Buscar el estadoId correspondiente
    const estadoObj = await prisma.estadosTransaccion.findFirst({
      where: { nombre: { equals: estado, mode: 'insensitive' } }
    });

    if (!estadoObj) {
      return res.status(400).json({ ok: false, message: 'Estado de transacción no válido' });
    }

    // Crear la transacción
    const transaccion = await prisma.transacciones.create({
      data: {
        productoId,
        cantidad,
        compradorId: req.user.userId,
        vendedorId: producto.vendedorId,
        estadoId: estadoObj.id,
        fecha: new Date()
      },
      include: {
        producto: { select: { id: true, nombre: true } },
        comprador: { select: { id: true, nombre: true, correo: true } },
        vendedor: { select: { id: true, nombre: true, correo: true } },
        estado: true
      }
    });

    res.status(201).json({
      ok: true,
      message: 'Transacción creada exitosamente',
      transaccion: {
        id: transaccion.id,
        producto: transaccion.producto,
        cantidad: transaccion.cantidad,
        comprador: transaccion.comprador,
        vendedor: transaccion.vendedor,
        estado: transaccion.estado.nombre,
        fecha: transaccion.fecha
      }
    });
  } catch (error) {
    console.error('❌ Error creando transacción:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

module.exports = router;