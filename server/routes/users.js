// users.js
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
    }); res.json({
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

// POST /api/users/rate/:sellerId - Calificar a un vendedor
router.post('/rate/:sellerId', authenticateToken, async (req, res, next) => {
  try {
    const { sellerId } = req.params;
    const { puntuacion, comentario } = req.body;
    const userId = req.user.userId;

    // 1️⃣ Validaciones básicas
    if (!puntuacion || puntuacion < 1 || puntuacion > 5) {
      throw new AppError(
        'La puntuación debe estar entre 1 y 5',
        'VALIDATION_ERROR',
        400,
        { field: 'puntuacion' }
      );
    }

    // 2️⃣ Verificar que haya al menos una transacción con este vendedor
    const transactionExists = await prisma.transacciones.findFirst({
      where: {
        compradorId: userId,
        vendedorId: parseInt(sellerId)
      }
    });

    if (!transactionExists) {
      throw new AppError(
        'No puedes calificar a este vendedor sin haber realizado una transacción',
        'NO_TRANSACTION_ERROR', // ✅ Código de error único
        400
      );
    }

    // 3️⃣ Verificar que el usuario no haya calificado antes al mismo vendedor para esta transacción
    const alreadyRated = await prisma.calificaciones.findFirst({
      where: {
        calificadorId: userId,
        calificadoId: parseInt(sellerId),
        transaccionId: transactionExists.id
      }
    });

    if (alreadyRated) {
      throw new AppError(
        'Ya has calificado esta transacción específica con este vendedor',
        'ALREADY_RATED_TRANSACTION_ERROR', // ✅ Código de error único
        400
      );
    }

    // 4️⃣ Crear la calificación
    const rating = await prisma.calificaciones.create({
      data: {
        transaccionId: transactionExists.id,
        calificadorId: userId,
        calificadoId: parseInt(sellerId),
        puntuacion,
        comentario
      }
    });

    // 5️⃣ Recalcular la reputación promedio del vendedor
    const promedio = await prisma.calificaciones.aggregate({
      where: { calificadoId: parseInt(sellerId) },
      _avg: { puntuacion: true }
    });

    await prisma.cuentas.update({
      where: { id: parseInt(sellerId) },
      data: { reputacion: promedio._avg.puntuacion || 0 }
    });

    // 6️⃣ Respuesta
    res.status(201).json({
      success: true,
      message: 'Calificación registrada correctamente',
      data: {
        rating,
        reputacionPromedio: promedio._avg.puntuacion || 0
      }
    });

  } catch (error) {
    next(error);
  }
});

// GET /api/users/:sellerId/ratings - Obtener todas las calificaciones de un vendedor
router.get('/:sellerId/ratings', authenticateToken, async (req, res, next) => {
  try {
    const { sellerId } = req.params;

    const ratings = await prisma.calificaciones.findMany({
      where: { calificadoId: parseInt(sellerId) },
      include: {
        calificador: {
          select: { id: true, usuario: true, nombre: true, apellido: true }
        }
      },
      orderBy: { id: 'desc' }
    });

    res.json({
      success: true,
      data: ratings.map(r => ({
        id: r.id,
        puntuacion: r.puntuacion,
        comentario: r.comentario,
        fecha: r.fechaCreacion,
        calificador: r.calificador,
      }))
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
