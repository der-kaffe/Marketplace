const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// ---------------- GET /api/publications ----------------
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, search } = req.query;

    const where = {};
    if (search) {
      where.OR = [
        { titulo: { contains: search, mode: 'insensitive' } },
        { cuerpo: { contains: search, mode: 'insensitive' } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const publications = await prisma.publicaciones.findMany({
      where,
      include: {
        usuario: {
          select: { id: true, nombre: true, apellido: true, usuario: true }
        }
      },
      orderBy: { fecha: 'desc' },
      skip,
      take: parseInt(limit)
    });

    const total = await prisma.publicaciones.count({ where });

    res.json({
      ok: true,
      publications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error listando publicaciones:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ---------------- POST /api/publications ----------------
router.post(
  '/',
  authenticateToken,
  [
    body('titulo')
      .isLength({ min: 3 })
      .withMessage('El título debe tener al menos 3 caracteres'),
    body('cuerpo')
      .isLength({ min: 10 })
      .withMessage('El cuerpo debe tener al menos 10 caracteres'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          ok: false,
          message: 'Datos inválidos',
          errors: errors.array(),
        });
      }

      const { titulo, cuerpo, estado } = req.body;

      const newPublication = await prisma.publicaciones.create({
        data: {
          titulo,
          cuerpo,
          estado: estado || 'Activo',
          usuarioId: req.user.userId
        },
        include: {
          usuario: {
            select: { id: true, nombre: true, apellido: true, usuario: true }
          }
        }
      });

      res.status(201).json({
        ok: true,
        message: 'Publicación creada exitosamente',
        publication: newPublication
      });
    } catch (error) {
      console.error('Error creando publicación:', error);
      res.status(500).json({ ok: false, message: 'Error interno del servidor' });
    }
  }
);

module.exports = router;
