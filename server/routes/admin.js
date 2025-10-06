// routes/admin.js
const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireAdmin } = require('../middleware/auth'); // pendiente

// Ruta para obtener todos los usuarios (por ahora "async")
router.get('/users', async (req, res) => {
  try {
    const users = await prisma.cuentas.findMany({
      //orderBy: { fechaRegistro: 'desc' },
      orderBy: { id: 'asc' },
      select: {
        id: true,
        nombre: true,
        apellido: true,
        correo: true,
        usuario: true,
        rolId: true,
        estadoId: true,
        fechaRegistro: true,
        campus: true,
        reputacion: true
      }
    });

    res.json({ total: users.length, users });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error obteniendo usuarios' });
  }
});

// Eliminar usuario por id (por ahora "async", sin token)
router.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Verificamos si existe
    const user = await prisma.cuentas.findUnique({
      where: { id: parseInt(id) }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Eliminar
    await prisma.cuentas.delete({
      where: { id: parseInt(id) }
    });

    res.json({ success: true, message: 'Usuario eliminado correctamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error eliminando usuario' });
  }
});

module.exports = router;