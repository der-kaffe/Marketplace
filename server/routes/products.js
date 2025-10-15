//products.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/products - Listar productos
router.get('/', async (req, res) => {
  try {
    const { category, search, page = 1, limit = 20 } = req.query;
    
    // ✅ SOLUCIÓN 1: Validar página mínima
    const currentPage = Math.max(1, parseInt(page) || 1);
    const currentLimit = Math.max(1, Math.min(100, parseInt(limit) || 20));
    
    console.log(`📊 Obteniendo productos - Página: ${currentPage}, Límite: ${currentLimit}`);
    
    // Construir filtros para la nueva estructura
    const where = {
      estadoId: 1 // Solo productos disponibles
    };
    
    if (category) {
      where.categoria = {
        nombre: { contains: category, mode: 'insensitive' }
      };
    }
    
    if (search) {
      where.OR = [
        { nombre: { contains: search, mode: 'insensitive' } },
        { descripcion: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    // ✅ SOLUCIÓN 2: Skip siempre positivo
    const skip = Math.max(0, (currentPage - 1) * currentLimit);
    
    console.log(`🔢 Calculando skip: ${skip} = (${currentPage} - 1) * ${currentLimit}`);

    // Verificamos si hay usuario autenticado
    const user = req.user; // viene desde middleware de auth

    // Base: solo productos activos
    const whereClause = {
      ...where, // mantiene filtros de categoría, búsqueda y estadoId
    };

    // Añadir reglas según tipo de usuario
    if (!user) {
      // Usuario no logeado → solo visibles
      whereClause.visible = true;
    } else if (user.role === "CLIENTE") {
      whereClause.visible = true;
    } else if (user.role === "VENDEDOR") {
      whereClause.vendedorId = user.userId;
    } else if (user.role === "ADMIN") {
      // Admin ve todo
    }

    // Obtener productos con información del vendedor y categoría
    const products = await prisma.productos.findMany({
      where: whereClause,
      include: {
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            campus: true,
            reputacion: true
          }
        },
        categoria: true,
        estado: true,
        imagenes: true
      },
      orderBy: [
        { fechaAgregado: 'desc' }
      ],
      skip,
      take: currentLimit
    });

    // Obtener total para paginación
    const total = await prisma.productos.count({ where: whereClause });

    console.log(`✅ Productos encontrados: ${products.length}/${total}`);

    // ✅ SOLUCIÓN 3: Conversión segura de tipos
    const formattedProducts = products.map(product => ({
      id: product.id,
      nombre: product.nombre,
      descripcion: product.descripcion,
      // ✅ Conversión segura de Decimal a number
      precioAnterior: product.precioAnterior ? Number(product.precioAnterior) : null,
      precioActual: product.precioActual ? Number(product.precioActual) : null,
      categoria: product.categoria?.nombre,
      // ✅ Conversión segura de calificación
      calificacion: product.calificacion ? Number(product.calificacion) : null,
      cantidad: product.cantidad,
      estado: product.estado.nombre,
      fechaAgregado: product.fechaAgregado,
      imagenes: product.imagenes,
      vendedor: {
        id: product.vendedor.id,
        nombre: product.vendedor.nombre,
        apellido: product.vendedor.apellido,
        correo: product.vendedor.correo,
        campus: product.vendedor.campus,
        // ✅ Conversión segura de reputación
        reputacion: product.vendedor.reputacion ? Number(product.vendedor.reputacion) : 0
      }
    }));

    res.json({
      ok: true,
      products: formattedProducts,
      pagination: {
        page: currentPage,
        limit: currentLimit,
        total,
        totalPages: Math.max(1, Math.ceil(total / currentLimit))
      }
    });

  } catch (error) {
    console.error('❌ Error listando productos:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/products/:id - Obtener producto por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const product = await prisma.productos.findUnique({
      where: { 
        id: parseInt(id)
      },
      include: {
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            campus: true,
            reputacion: true
          }
        },
        categoria: true,
        estado: true,
        imagenes: true
      }
    });

    if (!product || product.estadoId !== 1) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    // ✅ SOLUCIÓN 4: Conversión segura para producto individual
    const formattedProduct = {
      id: product.id,
      nombre: product.nombre,
      descripcion: product.descripcion,
      precioAnterior: product.precioAnterior ? Number(product.precioAnterior) : null,
      precioActual: product.precioActual ? Number(product.precioActual) : null,
      categoria: product.categoria?.nombre,
      calificacion: product.calificacion ? Number(product.calificacion) : null,
      cantidad: product.cantidad,
      estado: product.estado.nombre,
      fechaAgregado: product.fechaAgregado,
      imagenes: product.imagenes,
      vendedor: {
        ...product.vendedor,
        reputacion: product.vendedor.reputacion ? Number(product.vendedor.reputacion) : 0
      }
    };

    res.json({
      ok: true,
      product: formattedProduct
    });

  } catch (error) {
    console.error('❌ Error obteniendo producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/products - Crear producto
router.post('/', authenticateToken, [
  body('nombre').isLength({ min: 3 }).withMessage('Nombre debe tener al menos 3 caracteres'),
  body('descripcion').isLength({ min: 10 }).withMessage('Descripción debe tener al menos 10 caracteres'),
  body('precioActual').isFloat({ min: 0 }).withMessage('Precio debe ser un número positivo'),
  body('categoriaId').isInt({ min: 1 }).withMessage('Debe seleccionar una categoría válida')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        ok: false,
        message: 'Datos de entrada inválidos',
        errors: errors.array()
      });
    }

    const { 
      nombre, 
      descripcion, 
      precioAnterior, 
      precioActual,
      categoriaId,
      cantidad
    } = req.body;

    // Verificar que la categoría existe
    const categoria = await prisma.categorias.findUnique({
      where: { id: parseInt(categoriaId) }
    });

    if (!categoria) {
      return res.status(400).json({
        ok: false,
        message: 'Categoría no encontrada'
      });
    }

    const newProduct = await prisma.productos.create({
      data: {
        nombre,
        descripcion,
        precioAnterior: precioAnterior ? parseFloat(precioAnterior) : null,
        precioActual: parseFloat(precioActual),
        categoriaId: parseInt(categoriaId),
        vendedorId: req.user.userId,
        cantidad: cantidad ? parseInt(cantidad) : 1,
        estadoId: 1, // Estado "Disponible"
        calificacion: 0.0
      },
      include: {
        categoria: true,
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true
          }
        },
        estado: true
      }
    });

    res.status(201).json({
      ok: true,
      message: 'Producto creado exitosamente',
      product: newProduct
    });

  } catch (error) {
    console.error('❌ Error creando producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/products/categories - Obtener categorías
router.get('/categories/list', async (req, res) => {
  try {
    const categories = await prisma.categorias.findMany({
      orderBy: {
        nombre: 'asc'
      },
      include: {
        subcategorias: true,
        categoriaPadre: true
      }
    });

    res.json({
      ok: true,
      categories: categories.map(cat => ({
        id: cat.id,
        nombre: cat.nombre,
        categoriaPadreId: cat.categoriaPadreId,
        subcategorias: cat.subcategorias?.map(sub => ({
          id: sub.id,
          nombre: sub.nombre
        })) || []
      }))
    });

  } catch (error) {
    console.error('❌ Error obteniendo categorías:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// Cambiar visibilidad del producto
router.patch("/:id/visibility", authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { visible } = req.body;

    const producto = await prisma.productos.findUnique({
      where: { id: parseInt(id) },
    });

    if (typeof visible !== "boolean") {
      return res.status(400).json({ ok: false, message: "El valor de 'visible' debe ser booleano (true o false)" });
    }

    if (!producto) {
      return res.status(404).json({ ok: false, message: "Producto no encontrado" });
    }

    // Solo el vendedor o admin puede cambiar visibilidad
    if (producto.vendedorId !== req.user.userId && req.user.role !== "ADMIN") {
      return res
        .status(403)
        .json({ ok: false, message: "No tienes permiso para modificar este producto" });
    }

    const actualizado = await prisma.productos.update({
      where: { id: parseInt(id) },
      data: { visible },
    });

    res.json({ ok: true, message: "Visibilidad actualizada", producto: actualizado });
  } catch (error) {
    console.error("❌ Error al cambiar visibilidad:", error);
    res.status(500).json({ ok: false, message: "Error interno al cambiar visibilidad" });
  }
});


module.exports = router;