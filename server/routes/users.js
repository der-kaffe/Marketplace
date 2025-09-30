const express = require('express');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/users/profile - Obtener perfil del usuario actual
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.cuentas.findUnique({
      where: { id: req.user.userId },
      include: {
        rol: true,
        estado: true,
        resumenUsuario: true
      }
    });

    if (!user) {
      return res.status(404).json({
        ok: false,
        message: 'Usuario no encontrado'
      });
    }

    res.json({
      ok: true,
      user: {
        id: user.id,
        correo: user.correo,
        usuario: user.usuario,
        nombre: user.nombre,
        apellido: user.apellido,
        role: user.rol.nombre,
        estado: user.estado.nombre,
        campus: user.campus,
        reputacion: user.reputacion,
        fechaRegistro: user.fechaRegistro,
        resumen: user.resumenUsuario
      }
    });

  } catch (error) {
    console.error('Error obteniendo perfil:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/users - Listar usuarios (solo admin)
router.get('/', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'Administrador') {
      return res.status(403).json({
        ok: false,
        message: 'Acceso denegado'
      });
    }

    const users = await prisma.cuentas.findMany({
      include: {
        rol: true,
        estado: true,
        resumenUsuario: true
      },
      orderBy: {
        fechaRegistro: 'desc'
      }
    });

    res.json({
      ok: true,      users: users.map(user => ({
        id: user.id,        correo: user.correo,
        usuario: user.usuario,
        nombre: user.nombre,
        apellido: user.apellido,
        role: user.rol.nombre,
        estado: user.estado.nombre,
        campus: user.campus,
        reputacion: user.reputacion,
        fechaRegistro: user.fechaRegistro,
        resumen: user.resumenUsuario
      }))
    });

  } catch (error) {
    console.error('Error listando usuarios:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

module.exports = router;
