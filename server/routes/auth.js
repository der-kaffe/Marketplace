const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database'); express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');

const router = express.Router();

// Middleware de validación de errores
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      ok: false,
      message: 'Datos de entrada inválidos',
      errors: errors.array()
    });
  }
  next();
};

// POST /api/auth/login - Login con email y password
router.post('/login', [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email debe ser válido'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password debe tener al menos 6 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password } = req.body;    // Buscar usuario
    const user = await prisma.cuentas.findFirst({
      where: {
        correo: email,
        estadoId: 1 // Estado activo
      },
      include: {
        rol: true,
        estado: true
      }
    });

    if (!user) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }    // Verificar password
    const passwordMatch = await bcrypt.compare(password, user.contrasena);
    if (!passwordMatch) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }    // Generar JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.correo, 
        role: user.rol.nombre 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      ok: true,
      message: 'Login exitoso',
      token,
      user: {
        id: user.id,
        email: user.correo,
        nombre: user.nombre,
        apellido: user.apellido,
        role: user.rol.nombre,
        campus: user.campus,
        reputacion: user.reputacion
      }
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/auth/register - Registro de usuario
router.post('/register', [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email debe ser válido')
    .custom(async (email) => {
      // Verificar que sea dominio UCT
      if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
        throw new Error('Solo se permiten correos de @uct.cl o @alu.uct.cl');
      }
    }),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password debe tener al menos 6 caracteres'),
  body('nombre')
    .isLength({ min: 2 })
    .withMessage('Nombre debe tener al menos 2 caracteres'),
  body('usuario')
    .isLength({ min: 3 })
    .withMessage('Usuario debe tener al menos 3 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password, nombre, usuario } = req.body;

    // Verificar si el usuario ya existe (por correo o usuario)
    const existingUser = await prisma.cuentas.findFirst({
      where: {
        OR: [
          { correo: email },
          { usuario: usuario }
        ]
      }
    });

    if (existingUser) {
      const campo = existingUser.correo === email ? 'correo' : 'usuario';
      return res.status(409).json({
        ok: false,
        message: `El ${campo} ya está en uso`
      });
    }

    // Hashear password
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);

    // Determinar rol según email
    const rolId = email.endsWith('@uct.cl') ? 2 : 3; // 2 = Vendedor, 3 = Cliente

    // Crear usuario
    const newUser = await prisma.cuentas.create({
      data: {
        correo: email,
        contrasena: hashedPassword,
        nombre: nombre,
        usuario: usuario,
        apellido: '', // Se puede actualizar después
        rolId: rolId,
        estadoId: 1, // Estado activo
        campus: 'Campus Temuco'
      },
      include: {
        rol: true,
        estado: true
      }    });

    // Crear resumen inicial del usuario
    await prisma.resumenUsuario.create({
      data: {
        usuarioId: newUser.id,
        totalProductos: 0,
        totalVentas: 0,
        totalCompras: 0,
        promedioCalificacion: 0.0
      }
    });

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: newUser.id, 
        email: newUser.correo, 
        role: newUser.rol.nombre 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );    res.status(201).json({
      ok: true,
      message: 'Usuario registrado exitosamente',
      token,
      user: {
        id: newUser.id,
        correo: newUser.correo,
        usuario: newUser.usuario,
        nombre: newUser.nombre,
        apellido: newUser.apellido,
        role: newUser.rol.nombre,
        campus: newUser.campus
      }
    });

  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/auth/google - Login con Google
router.post('/google', [
  body('idToken').notEmpty().withMessage('ID Token es requerido'),
  body('email').isEmail().withMessage('Email debe ser válido'),
  body('name').notEmpty().withMessage('Nombre es requerido'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { idToken, email, name, googleId, avatarUrl } = req.body;

    // Verificar dominio UCT
    if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
      return res.status(403).json({
        ok: false,
        message: 'Solo se permiten correos de @uct.cl o @alu.uct.cl'
      });
    }    // Buscar usuario existente
    let user = await prisma.cuentas.findFirst({
      where: {
        correo: email,
        estadoId: 1 // Estado activo
      },
      include: {
        rol: true,
        estado: true
      }
    });

    if (!user) {
      // Determinar rol según email
      const rolId = email.endsWith('@uct.cl') ? 2 : 3; // 2 = Vendedor, 3 = Cliente
      
      // Generar usuario único basado en el nombre
      const baseUsuario = name.toLowerCase().replace(/\s+/g, '_');
      const usuario = `${baseUsuario}_${Date.now()}`;
      
      // Crear nuevo usuario
      user = await prisma.cuentas.create({
        data: {
          correo: email,
          contrasena: '', // Google auth no requiere password
          nombre: name,
          usuario: usuario,
          apellido: '',
          rolId: rolId,
          estadoId: 1, // Estado activo
          campus: 'Campus Temuco'
        },
        include: {
          rol: true,
          estado: true
        }
      });

      // Crear resumen inicial del usuario
      await prisma.resumenUsuario.create({
        data: {
          usuarioId: user.id,
          totalProductos: 0,
          totalVentas: 0,
          totalCompras: 0,
          promedioCalificacion: 0.0
        }
      });    }

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.correo, 
        role: user.rol.nombre 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      ok: true,
      message: 'Login con Google exitoso',
      token,
      user: {
        id: user.id,
        correo: user.correo,
        usuario: user.usuario,
        nombre: user.nombre,
        apellido: user.apellido,
        role: user.rol.nombre,
        campus: user.campus
      }
    });

  } catch (error) {
    console.error('Error en login Google:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

module.exports = router;
