// routes/auth.js
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken, requireAdmin, requireVendor } = require('../middleware/auth');
const { loginLimiter, registerLimiter } = require('../middleware/rateLimiters');
const { generateTokenPair, verifyRefreshToken } = require('../utils/tokenUtils');
const { secureLog } = require('../middleware/secureLogger');

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
router.post('/login',
  loginLimiter, // 🔒 Rate limiting para login
  [
    body('email').isEmail().normalizeEmail().withMessage('Email debe ser valido'),
    body('password').isLength({ min: 6 }).withMessage('Password debe tener al menos 6 caracteres'),
    handleValidationErrors
  ],
  async (req, res) => {
    try {
      const { email, password } = req.body;

      const user = await prisma.cuentas.findFirst({
        where: { correo: email, estadoId: 1 },
        include: { rol: true, estado: true }
      });

      if (!user) {
        return res.status(401).json({ ok: false, message: 'Credenciales invalidas' });
      }

      const passwordMatch = await bcrypt.compare(password, user.contrasena);
      if (!passwordMatch) {
        return res.status(401).json({ ok: false, message: 'Credenciales invalidas' });
      }    // 🔒 Generar par de tokens (access + refresh)
      const tokenPayload = {
        userId: user.id,
        email: user.correo,
        role: user.rol.nombre.toUpperCase()
      };
      const { accessToken, refreshToken } = generateTokenPair(tokenPayload);

      secureLog.info('Usuario logueado exitosamente', {
        userId: user.id,
        email: user.correo,
        role: user.rol.nombre
      });

      res.json({
        ok: true,
        message: 'Login exitoso',
        token: accessToken, // Mantener compatibilidad
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.correo,
          nombre: user.nombre,
          role: user.rol.nombre.toUpperCase(),
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
router.post('/register',
  registerLimiter, // 🔒 Rate limiting para registro
  [
    body('email')
      .isEmail().normalizeEmail().withMessage('Email debe ser valido')
      .isLength({ max: 100 }).withMessage('Email muy largo')
      .custom(async (email) => {
        if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
          throw new Error('Solo se permiten correos de @uct.cl o @alu.uct.cl');
        }
      }),
    body('password')
      .isLength({ min: 8, max: 128 }).withMessage('Password debe tener entre 8 y 128 caracteres')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .withMessage('Password debe tener mayúscula, minúscula, número y símbolo especial'),
    body('nombre')
      .trim()
      .isLength({ min: 2, max: 50 }).withMessage('Nombre debe tener entre 2 y 50 caracteres')
      .matches(/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/).withMessage('Nombre solo debe contener letras'),
    body('usuario')
      .trim()
      .isLength({ min: 3, max: 30 }).withMessage('Usuario debe tener entre 3 y 30 caracteres')
      .matches(/^[a-zA-Z0-9_-]+$/).withMessage('Usuario solo debe contener letras, números, _ y -'),
    handleValidationErrors
  ],
  async (req, res) => {
    try {
      const { email, password, nombre, usuario } = req.body;

      const existingUser = await prisma.cuentas.findFirst({
        where: { OR: [{ correo: email }, { usuario: usuario }] }
      });

      if (existingUser) {
        const campo = existingUser.correo === email ? 'correo' : 'usuario';
        return res.status(409).json({ ok: false, message: `El ${campo} ya esta en uso` });
      }

      const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);
      const rolId = email.endsWith('@uct.cl') ? 2 : 3;

      const newUser = await prisma.cuentas.create({
        data: {
          correo: email,
          contrasena: hashedPassword,
          nombre,
          usuario,
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
        { userId: newUser.id, email: newUser.correo, role: newUser.rol.nombre.toUpperCase() },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.status(201).json({
        ok: true,
        message: 'Usuario registrado exitosamente',
        token,
        user: {
          id: newUser.id,
          correo: newUser.correo,
          usuario: newUser.usuario,
          nombre: newUser.nombre,
          role: newUser.rol.nombre.toUpperCase(),
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

    if (!email.endsWith('@uct.cl') && !email.endsWith('@alu.uct.cl')) {
      return res.status(403).json({ ok: false, message: 'Solo se permiten correos de @uct.cl o @alu.uct.cl' });
    }

    let user = await prisma.cuentas.findFirst({
      where: { correo: email, estadoId: 1 },
      include: { rol: true, estado: true }
    }); if (!user) {
      // Todos los usuarios de Google son "Cliente" por defecto (ID 3)
      const rolId = 3; // Cliente
      const baseUsuario = name.toLowerCase().replace(/\s+/g, '_');
      const usuario = `${baseUsuario}_${Date.now()}`;

      user = await prisma.cuentas.create({
        data: {
          correo: email,
          contrasena: '',
          nombre: name,
          usuario,
          rolId,
          estadoId: 1,
          campus: 'Campus Temuco'
        },
        include: { rol: true, estado: true }
      });

      await prisma.resumenUsuario.create({
        data: {
          usuarioId: user.id,
          totalProductos: 0,
          totalVentas: 0,
          totalCompras: 0,
          promedioCalificacion: 0.0
        }
      });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.correo, role: user.rol.nombre.toUpperCase() },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    ); res.json({
      ok: true,
      message: '¡Cuenta creada/actualizada en base de datos!',
      token,
      user: {
        id: user.id,
        correo: user.correo,        // 🔒 Solo lectura (viene de Google)
        nombre: user.nombre,        // 🔒 Solo lectura (viene de Google)
        usuario: user.usuario,      // ✏️ Editable por el usuario
        campus: user.campus || 'Campus Temuco',  // ✏️ Editable por el usuario
        role: user.rol.nombre.toUpperCase(),
        // Campos editables disponibles para actualizar después:
        editableFields: ['usuario', 'campus', 'telefono', 'direccion']
      }
    });
    console.log(token)
  } catch (error) {
    console.error('Error en login Google:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ------------------- PERFIL DEL USUARIO -------------------
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const { include } = req.query;
    // Ejemplos de uso:
    // /me                          -> trae todo
    // /me?include=perfil           -> solo datos básicos
    // /me?include=notificaciones
    // /me?include=productos,seguidores
    // /me?include=todo             -> todo explícitamente

    // Todas las relaciones disponibles
    const relacionesDisponibles = {
      rol: true,
      estado: true,
      productos: { include: { categoria: true, estado: true, imagenes: true } },
      transaccionesCompra: { include: { producto: true, vendedor: true, estado: true } },
      transaccionesVenta: { include: { producto: true, comprador: true, estado: true } },
      calificacionesDadas: { include: { calificado: true, transaccion: true } },
      calificacionesRecibidas: { include: { calificador: true, transaccion: true } },
      carrito: { include: { producto: true } },
      actividades: true,
      mensajesEnviados: { include: { destinatario: true } },
      mensajesRecibidos: { include: { remitente: true } },
      reportes: { include: { producto: true, usuarioReportado: true, estado: true } },
      reportesRecibidos: { include: { reportante: true, producto: true, estado: true } },
      publicaciones: true,
      foros: true,
      publicacionesForo: { include: { foro: true, comentarios: true } },
      comentariosPublicacion: { include: { publicacion: true } },
      notificaciones: true,
      ubicaciones: true,
      resumenUsuario: true,
      siguiendo: { include: { usuarioSeguido: true } },
      seguidores: { include: { usuarioSigue: true } },
    };

    let includeOptions = {};

    if (!include || include === "todo") {
      // Si no se pide nada o se pide "todo", incluir todo
      includeOptions = relacionesDisponibles;
    } else if (include === "perfil") {
      // Solo perfil básico, sin relaciones pesadas
      includeOptions = {
        rol: true,
        estado: true,
      };
    } else {
      // Se pidió algo específico, ejemplo: ?include=notificaciones,productos
      const partes = include.split(",");
      for (const key of partes) {
        if (relacionesDisponibles[key]) {
          includeOptions[key] = relacionesDisponibles[key];
        }
      }
      // Siempre incluir lo básico
      includeOptions.rol = true;
      includeOptions.estado = true;
    }

    const user = await prisma.cuentas.findUnique({
      where: { id: req.user.userId },
      include: includeOptions
    });

    if (!user) {
      return res.status(404).json({ ok: false, message: 'Usuario no encontrado' });
    }

    res.json({
      ok: true,
      user
    });
  } catch (error) {
    console.error('Error en /me:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ------------------- REFRESH TOKEN -------------------
router.post('/refresh', [
  body('refreshToken').notEmpty().withMessage('Refresh token requerido'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { refreshToken } = req.body;

    // Verificar refresh token
    const payload = verifyRefreshToken(refreshToken);

    // Verificar que el usuario aún existe y está activo
    const user = await prisma.cuentas.findFirst({
      where: {
        id: payload.userId,
        estadoId: 1
      },
      include: { rol: true }
    });

    if (!user) {
      secureLog.warn('Intento de refresh con usuario inválido', {
        userId: payload.userId
      });
      return res.status(401).json({
        ok: false,
        message: 'Usuario no encontrado o inactivo'
      });
    }

    // Generar nuevos tokens
    const newTokenPayload = {
      userId: user.id,
      email: user.correo,
      role: user.rol.nombre.toUpperCase()
    };
    const { accessToken, refreshToken: newRefreshToken } = generateTokenPair(newTokenPayload);

    secureLog.info('Tokens renovados exitosamente', {
      userId: user.id,
      email: user.correo
    });

    res.json({
      ok: true,
      message: 'Tokens renovados exitosamente',
      accessToken,
      refreshToken: newRefreshToken,
      token: accessToken // Mantener compatibilidad
    });

  } catch (error) {
    secureLog.error('Error en refresh token', error);
    res.status(403).json({
      ok: false,
      message: 'Refresh token inválido o expirado'
    });
  }
});

module.exports = router;
