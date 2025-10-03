const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Util simple para manejar errores de validación
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

// GET /api/favorites -> lista favoritos del usuario autenticado (de Productos)
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [favorites, total] = await Promise.all([
      prisma.favoritos.findMany({
        where: { usuarioId: req.user.userId },
        include: {
          producto: {
            include: {
              vendedor: { select: { id: true, nombre: true, apellido: true, correo: true } },
              categoria: true,
              estado: true,
              imagenes: true,
            },
          },
        },
        orderBy: { fecha: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.favoritos.count({ where: { usuarioId: req.user.userId } }),
    ]);

    res.json({
      ok: true,
      favorites,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Error listando favoritos:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// POST /api/favorites -> agrega favorito de un producto
router.post(
  '/',
  authenticateToken,
  [body('productoId').isInt().withMessage('productoId debe ser entero')],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { productoId } = req.body;

      // Verifica que el producto exista y esté disponible
      const producto = await prisma.productos.findUnique({ where: { id: Number(productoId) } });
      if (!producto) {
        return res.status(404).json({ ok: false, message: 'Producto no encontrado' });
      }

      const fav = await prisma.favoritos.create({
        data: {
          usuarioId: req.user.userId,
          productoId: Number(productoId),
        },
      });

      res.status(201).json({ ok: true, message: 'Producto añadido a favoritos', favorite: fav });
    } catch (error) {
      if (error.code === 'P2002') {
        return res.status(409).json({ ok: false, message: 'El producto ya está en favoritos' });
      }
      console.error('Error creando favorito:', error);
      res.status(500).json({ ok: false, message: 'Error interno del servidor' });
    }
  }
);

// DELETE /api/favorites/:productoId -> quita favorito
router.delete('/:productoId', authenticateToken, async (req, res) => {
  try {
    const productoId = Number(req.params.productoId);

    const result = await prisma.favoritos.deleteMany({
      where: { usuarioId: req.user.userId, productoId },
    });

    return res.json({ ok: true, message: 'Eliminado de favoritos', deleted: result.count });
  } catch (error) {
    console.error('Error eliminando favorito:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

module.exports = router;
