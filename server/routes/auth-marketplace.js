const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { pool } = require('../config/database');

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
    .withMessage('Email válido requerido'),
  body('password')
    .isLength({ min: 1 })
    .withMessage('Password requerido'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log('Intento de login:', email);

    // Buscar usuario por email en la tabla cuentas con información de rol y estado
    const [users] = await pool.execute(
      `SELECT c.*, r.nombre as rol_nombre, e.nombre as estado_nombre 
       FROM cuentas c 
       LEFT JOIN roles r ON c.rol_id = r.id 
       LEFT JOIN estados_usuario e ON c.estado_id = e.id 
       WHERE c.correo = ?`,
      [email]
    );

    if (users.length === 0) {
      console.log('Usuario no encontrado:', email);
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }

    const user = users[0];
    console.log('Usuario encontrado:', user.usuario, 'Estado:', user.estado_nombre);

    // Verificar si el usuario está activo
    if (user.estado_nombre !== 'Activo') {
      return res.status(403).json({
        ok: false,
        message: 'Usuario inactivo o suspendido'
      });
    }

    // Verificar password
    const isPasswordValid = await bcrypt.compare(password, user.contrasena);
    if (!isPasswordValid) {
      console.log('Password inválido para usuario:', email);
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }

    // Verificar dominio UCT
    const validDomains = ['@uct.cl', '@alu.uct.cl'];
    const isValidDomain = validDomains.some(domain => email.endsWith(domain));
    
    if (!isValidDomain) {
      return res.status(403).json({
        ok: false,
        message: 'Solo se permiten correos de la Universidad Católica de Temuco (@uct.cl, @alu.uct.cl)'
      });
    }

    // Generar tokens
    const accessToken = jwt.sign(
      { 
        userId: user.id, 
        email: user.correo, 
        role: user.rol_nombre || 'Usuario',
        username: user.usuario
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Registrar actividad del usuario
    try {
      await pool.execute(
        'INSERT INTO actividad_usuario (usuario_id, accion, detalles) VALUES (?, ?, ?)',
        [user.id, 'login', 'Inicio de sesión exitoso']
      );
    } catch (activityError) {
      console.log('Error registrando actividad:', activityError.message);
    }

    console.log('Login exitoso para usuario:', user.usuario);

    res.json({
      ok: true,
      message: 'Login exitoso',
      data: {
        user: {
          id: user.id,
          name: `${user.nombre} ${user.apellido || ''}`.trim(),
          email: user.correo,
          username: user.usuario,
          role: user.rol_nombre || 'Usuario',
          campus: user.campus,
          reputation: parseFloat(user.reputacion) || 0
        },
        accessToken,
        refreshToken
      }
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
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
  body('username')
    .isLength({ min: 3 })
    .withMessage('Nombre de usuario debe tener al menos 3 caracteres'),
  body('firstName')
    .isLength({ min: 2 })
    .withMessage('Nombre debe tener al menos 2 caracteres'),
  body('lastName')
    .optional()
    .isLength({ min: 2 })
    .withMessage('Apellido debe tener al menos 2 caracteres'),
  body('campus')
    .optional()
    .isLength({ min: 2 })
    .withMessage('Campus debe ser válido'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password, username, firstName, lastName, campus } = req.body;

    // Verificar si el usuario ya existe (email o username)
    const [existingUsers] = await pool.execute(
      'SELECT id FROM cuentas WHERE correo = ? OR usuario = ?',
      [email, username]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        ok: false,
        message: 'El usuario o email ya existe'
      });
    }

    // Obtener rol por defecto (Usuario)
    const [roles] = await pool.execute(
      'SELECT id FROM roles WHERE nombre = ?',
      ['Usuario']
    );

    // Obtener estado activo
    const [estados] = await pool.execute(
      'SELECT id FROM estados_usuario WHERE nombre = ?',
      ['Activo']
    );

    const rolId = roles.length > 0 ? roles[0].id : 1;
    const estadoId = estados.length > 0 ? estados[0].id : 1;

    // Hashear password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const [result] = await pool.execute(
      `INSERT INTO cuentas (nombre, apellido, correo, usuario, contrasena, rol_id, estado_id, campus, reputacion) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [firstName, lastName || '', email, username, hashedPassword, rolId, estadoId, campus || '', 0.00]
    );

    // Registrar actividad
    try {
      await pool.execute(
        'INSERT INTO actividad_usuario (usuario_id, accion, detalles) VALUES (?, ?, ?)',
        [result.insertId, 'registro', 'Usuario registrado exitosamente']
      );
    } catch (activityError) {
      console.log('Error registrando actividad:', activityError.message);
    }

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: result.insertId, 
        email, 
        role: 'Usuario',
        username 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      ok: true,
      message: 'Usuario registrado exitosamente',
      data: {
        user: {
          id: result.insertId,
          name: `${firstName} ${lastName || ''}`.trim(),
          email,
          username,
          role: 'Usuario',
          campus: campus || '',
          reputation: 0
        },
        accessToken: token
      }
    });

  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/auth/profile - Obtener perfil del usuario
router.get('/profile', async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        ok: false,
        message: 'Token no proporcionado'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Obtener información actualizada del usuario
    const [users] = await pool.execute(
      `SELECT c.*, r.nombre as rol_nombre, e.nombre as estado_nombre 
       FROM cuentas c 
       LEFT JOIN roles r ON c.rol_id = r.id 
       LEFT JOIN estados_usuario e ON c.estado_id = e.id 
       WHERE c.id = ?`,
      [decoded.userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        ok: false,
        message: 'Usuario no encontrado'
      });
    }

    const user = users[0];

    res.json({
      ok: true,
      data: {
        user: {
          id: user.id,
          name: `${user.nombre} ${user.apellido || ''}`.trim(),
          email: user.correo,
          username: user.usuario,
          role: user.rol_nombre,
          campus: user.campus,
          reputation: parseFloat(user.reputacion) || 0,
          registerDate: user.fecha_registro,
          status: user.estado_nombre
        }
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

// POST /api/auth/test-password - Endpoint para probar hasheado de contraseñas
router.post('/test-password', async (req, res) => {
  try {
    const { password } = req.body;
    
    if (!password) {
      return res.status(400).json({
        ok: false,
        message: 'Password requerido'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    
    res.json({
      ok: true,
      data: {
        originalPassword: password,
        hashedPassword: hashedPassword,
        isMatch: await bcrypt.compare(password, hashedPassword)
      }
    });

  } catch (error) {
    console.error('Error en test-password:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

module.exports = router;
