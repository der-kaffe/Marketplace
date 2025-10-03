// routes/auth.js
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken, requireAdmin, requireVendor } = require('../middleware/auth');

const router = express.Router();

// Middleware de validacion de errores
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      ok: false,
      message: 'Datos de entrada invalidos',
      errors: errors.array()
    });
  }
  next();
};

// ------------------- LOGIN -------------------
router.post('/login', [
  body('email').isEmail().normalizeEmail().withMessage('Email debe ser valido'),
  body('password').isLength({ min: 6 }).withMessage('Password debe tener al menos 6 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.cuentas.findFirst({
      where: { correo: email, estadoId: 1 },
      include: { rol: true, estado: true }
    });

    if (!user) {
      return res.status(400).json({ ok: false, message: 'Credenciales inválidas' });
    }

    const passwordMatch = await bcrypt.compare(password, user.contrasena);
    if (!passwordMatch) {
      return res.status(400).json({ ok: false, message: 'Credenciales inválidas' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.correo, role: user.rol.nombre },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const fullName = [user.nombre, user.apellido].filter(Boolean).join(' ').trim();

    res.json({
      ok: true,
      message: 'Login exitoso',
      token,
      user: {
        id: user.id,
        email: user.correo,
        nombre: user.nombre,
        apellido: user.apellido,
        name: fullName,
        role: user.rol.nombre,
        campus: user.campus,
        reputacion: user.reputacion
      }
    });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ------------------- REGISTER -------------------
router.post('/register', [
  body('email')
    .isEmail().normalizeEmail().withMessage('Email debe ser valido')
    .custom(async (email) => {
      if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
        throw new Error('Solo se permiten correos de @uct.cl o @alu.uct.cl');
      }
    }),
  body('password').isLength({ min: 6 }).withMessage('Password debe tener al menos 6 caracteres'),
  body('nombre').isLength({ min: 2 }).withMessage('Nombre debe tener al menos 2 caracteres'),
  body('usuario').isLength({ min: 3 }).withMessage('Usuario debe tener al menos 3 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password, nombre, usuario } = req.body;

    const existingUser = await prisma.cuentas.findFirst({
      where: { OR: [{ correo: email }, { usuario: usuario }] }
    });

    if (existingUser) {
      return res.status(409).json({ ok: false, message: 'Email o usuario ya registrado' });
    }

    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);
    const rolId = email.endsWith('@uct.cl') ? 2 : 3;

    const newUser = await prisma.cuentas.create({
      data: {
        correo: email,
        contrasena: hashedPassword,
        nombre,
        usuario,
        apellido: '',
        rolId,
        estadoId: 1,
        campus: 'Campus Temuco'
      },
      include: { rol: true, estado: true }
    });

    await prisma.resumenUsuario.create({
      data: {
        usuarioId: newUser.id,
        totalProductos: 0,
        totalVentas: 0,
        totalCompras: 0,
        promedioCalificacion: 0.0
      }
    });

    const token = jwt.sign(
      { userId: newUser.id, email: newUser.correo, role: newUser.rol.nombre },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const fullName = [newUser.nombre, newUser.apellido].filter(Boolean).join(' ').trim();

    res.status(201).json({
      ok: true,
      message: 'Usuario registrado exitosamente',
      token,
      user: {
        id: newUser.id,
        correo: newUser.correo,
        email: newUser.correo,
        usuario: newUser.usuario,
        nombre: newUser.nombre,
        apellido: newUser.apellido,
        name: fullName,
        role: newUser.rol.nombre,
        campus: newUser.campus
      }
    });
  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ------------------- GOOGLE LOGIN -------------------
router.post('/google', [
  body('idToken').notEmpty().withMessage('ID Token es requerido'),
  body('email').isEmail().withMessage('Email debe ser valido'),
  body('name').notEmpty().withMessage('Nombre es requerido'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, name } = req.body;

    // Validación simple de dominio
    if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
      return res.status(400).json({ ok: false, message: 'Dominio de email no permitido' });
    }

    // Buscar o crear usuario
    let user = await prisma.cuentas.findFirst({
      where: { correo: email, estadoId: 1 },
      include: { rol: true, estado: true }
    });

    if (!user) {
      // Si no existe, crear usuario básico con rol según dominio
      const rolId = email.endsWith('@uct.cl') ? 2 : 3;
      const nombre = name.split(' ')[0] || name;
      const apellido = name.split(' ').slice(1).join(' ');
      user = await prisma.cuentas.create({
        data: {
          correo: email,
          contrasena: '', // login federado, no se usa
          nombre,
          apellido,
          usuario: email.split('@')[0],
          rolId,
          estadoId: 1,
          campus: 'Campus Temuco'
        },
        include: { rol: true, estado: true }
      });

      // Crear resumen si no existe
      await prisma.resumenUsuario.create({
        data: {
          usuarioId: user.id,
          totalProductos: 0,
          totalVentas: 0,
          totalCompras: 0,
          promedioCalificacion: 0.0
        }
      }).catch(() => {});
    }

    const token = jwt.sign(
      { userId: user.id, email: user.correo, role: user.rol.nombre },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const fullName = [user.nombre, user.apellido].filter(Boolean).join(' ').trim();

    return res.json({
      ok: true,
      message: 'Login con Google exitoso',
      token,
      user: {
        id: user.id,
        email: user.correo,
        nombre: user.nombre,
        apellido: user.apellido,
        name: fullName,
        role: user.rol.nombre,
        campus: user.campus,
        reputacion: user.reputacion
      }
    });
  } catch (error) {
    console.error('Error en Google login:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ------------------- PERFIL DEL USUARIO -------------------
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.cuentas.findUnique({
      where: { id: req.user.userId },
      include: { rol: true, estado: true }
    });
    if (!user) return res.status(404).json({ ok: false, message: 'Usuario no encontrado' });

    const fullName = [user.nombre, user.apellido].filter(Boolean).join(' ').trim();

    return res.json({
      ok: true,
      user: {
        id: user.id,
        email: user.correo,
        nombre: user.nombre,
        apellido: user.apellido,
        name: fullName,
        role: user.rol.nombre,
        campus: user.campus,
        reputacion: user.reputacion
      }
    });
  } catch (error) {
    console.error('Error obteniendo perfil:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

module.exports = router;
