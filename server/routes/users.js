const express = require('express');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const AppError = require('../utils/AppError');

const router = express.Router();

// GET /api/users/profile - Obtener perfil del usuario actual
router.get('/profile', authenticateToken, async (req, res, next) => {
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
      throw new AppError(
        "Usuario no encontrado",
        "USER_NOT_FOUND",
        404,
        { field: "id" }
      );
    }

    res.json({
      success: true,
      data: {
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
    next(error); // lo captura el errorHandler
  }
});

// GET /api/users - Listar usuarios (solo admin)
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    if (req.user.role !== 'Administrador') {
      throw new AppError(
        "Acceso denegado",
        "FORBIDDEN",
        403,
        { requiredRole: "Administrador" }
      );
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
      success: true,
      data: users.map(user => ({
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
      }))
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
