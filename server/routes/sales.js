const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const venta = await prisma.transacciones.findUnique({
      where: { id: parseInt(req.params.id) },
      include: {
        producto: true,
        comprador: { select: { id: true, nombre: true, correo: true } },
        vendedor: { select: { id: true, nombre: true, correo: true } },
        estado: true
      }
    });

    if (!venta) {
      return res.status(404).json({ ok: false, message: 'Venta no encontrada' });
    }

    res.json({ ok: true, venta });
  } catch (error) {
    res.status(500).json({ ok: false, message: 'Error interno' });
  }
});
