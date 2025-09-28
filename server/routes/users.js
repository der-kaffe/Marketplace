const express = require('express');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/users/profile - Obtener perfil del usuario actual
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT id, email, name, role, avatar_url, created_at FROM users WHERE id = ?',
      [req.user.userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        ok: false,
        message: 'Usuario no encontrado'
      });
    }

    res.json({
      ok: true,
      user: users[0]
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
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        ok: false,
        message: 'Acceso denegado'
      });
    }

    const [users] = await pool.query(
      'SELECT id, email, name, role, is_active, created_at FROM users ORDER BY created_at DESC'
    );

    res.json({
      ok: true,
      users
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
