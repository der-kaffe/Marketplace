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

// PUT /api/users/profile - Actualizar perfil del usuario actual
router.put('/profile', authenticateToken, async (req, res, next) => {
  try {
    const { apellido, usuario, campus, telefono, direccion } = req.body;
    
    // Validar que al menos un campo sea enviado
    const updateData = {};
    if (apellido !== undefined) updateData.apellido = apellido;
    if (usuario !== undefined) updateData.usuario = usuario;
    if (campus !== undefined) updateData.campus = campus;
    if (telefono !== undefined) updateData.telefono = telefono;
    if (direccion !== undefined) updateData.direccion = direccion;

    if (Object.keys(updateData).length === 0) {
      throw new AppError(
        'Se debe proporcionar al menos un campo para actualizar',
        'VALIDATION_ERROR',
        400,
        { fields: ['apellido', 'usuario', 'campus', 'telefono', 'direccion'] }
      );
    }

    // Verificar que el nombre de usuario sea único si se está cambiando
    if (usuario) {
      const existingUser = await prisma.cuentas.findFirst({
        where: { 
          usuario,
          NOT: { id: req.user.userId }
        }
      });
      
      if (existingUser) {
        throw new AppError(
          'El nombre de usuario ya está en uso',
          'USERNAME_TAKEN',
          400,
          { field: 'usuario', value: usuario }
        );
      }
    }

    // Actualizar usuario
    const updatedUser = await prisma.cuentas.update({
      where: { id: req.user.userId },
      data: updateData,
      include: {
        rol: true,
        estado: true
      }
    });    res.json({
      ok: true,
      message: 'Perfil actualizado correctamente',
      user: {
        id: updatedUser.id,
        correo: updatedUser.correo,
        nombre: updatedUser.nombre,
        apellido: updatedUser.apellido || '',
        usuario: updatedUser.usuario,
        campus: updatedUser.campus || 'Campus Temuco',
        telefono: updatedUser.telefono,
        direccion: updatedUser.direccion,
        role: updatedUser.rol.nombre,
        editableFields: ['apellido', 'usuario', 'campus', 'telefono', 'direccion']
      }
    });

  } catch (error) {
    next(error);
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
