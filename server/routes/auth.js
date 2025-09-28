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
    .withMessage('Email debe ser válido'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password debe tener al menos 6 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password } = req.body;

    // Buscar usuario
    const [users] = await pool.query(
      'SELECT id, email, password, name, role, is_active FROM users WHERE email = ? AND is_active = TRUE',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }

    const user = users[0];

    // Verificar password
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      ok: true,
      message: 'Login exitoso',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
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
  body('name')
    .isLength({ min: 2 })
    .withMessage('Nombre debe tener al menos 2 caracteres'),
  handleValidationErrors
], async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Verificar si el usuario ya existe
    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        ok: false,
        message: 'El usuario ya existe'
      });
    }

    // Hashear password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const [result] = await pool.query(
      'INSERT INTO users (email, password, name, role, email_verified) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, name, 'student', true]
    );

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: result.insertId, 
        email, 
        role: 'student' 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      ok: true,
      message: 'Usuario registrado exitosamente',
      token,
      user: {
        id: result.insertId,
        email,
        name,
        role: 'student'
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
    }

    // Buscar o crear usuario
    let [users] = await pool.query(
      'SELECT id, email, name, role, is_active FROM users WHERE email = ? OR google_id = ?',
      [email, googleId]
    );

    let user;
    if (users.length === 0) {
      // Crear nuevo usuario
      const [result] = await pool.query(
        'INSERT INTO users (email, password, name, role, google_id, avatar_url, email_verified) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [email, '', name, 'student', googleId, avatarUrl, true]
      );
      
      user = {
        id: result.insertId,
        email,
        name,
        role: 'student'
      };
    } else {
      user = users[0];
      
      // Actualizar información de Google si es necesario
      await pool.query(
        'UPDATE users SET google_id = ?, avatar_url = ?, name = ? WHERE id = ?',
        [googleId, avatarUrl, name, user.id]
      );
    }

    // Generar JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      ok: true,
      message: 'Login con Google exitoso',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
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
