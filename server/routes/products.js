const express = require('express');
const { body, validationResult } = require('express-validator');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/products - Listar productos
router.get('/', async (req, res) => {
  try {
    const { category, search, page = 1, limit = 20 } = req.query;
    
    let query = `
      SELECT 
        p.id, p.title, p.description, p.price, p.category, p.condition_type,
        p.images, p.is_available, p.is_featured, p.created_at,
        u.name as seller_name, u.email as seller_email
      FROM products p
      JOIN users u ON p.user_id = u.id
      WHERE p.is_available = TRUE
    `;
    
    const queryParams = [];
    
    if (category) {
      query += ' AND p.category = ?';
      queryParams.push(category);
    }
    
    if (search) {
      query += ' AND (p.title LIKE ? OR p.description LIKE ?)';
      queryParams.push(`%${search}%`, `%${search}%`);
    }
    
    query += ' ORDER BY p.is_featured DESC, p.created_at DESC';
    query += ' LIMIT ? OFFSET ?';
    
    const offset = (page - 1) * limit;
    queryParams.push(parseInt(limit), offset);
    
    const [products] = await pool.query(query, queryParams);

    res.json({
      ok: true,
      products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: products.length
      }
    });

  } catch (error) {
    console.error('Error listando productos:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/products/:id - Obtener producto por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [products] = await pool.query(`
      SELECT 
        p.id, p.title, p.description, p.price, p.category, p.condition_type,
        p.images, p.is_available, p.is_featured, p.created_at,
        u.id as seller_id, u.name as seller_name, u.email as seller_email, u.avatar_url as seller_avatar
      FROM products p
      JOIN users u ON p.user_id = u.id
      WHERE p.id = ?
    `, [id]);

    if (products.length === 0) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    res.json({
      ok: true,
      product: products[0]
    });

  } catch (error) {
    console.error('Error obteniendo producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/products - Crear producto
router.post('/', authenticateToken, [
  body('title').isLength({ min: 3 }).withMessage('Título debe tener al menos 3 caracteres'),
  body('description').isLength({ min: 10 }).withMessage('Descripción debe tener al menos 10 caracteres'),
  body('price').isFloat({ min: 0 }).withMessage('Precio debe ser un número positivo'),
  body('category').isIn(['academic', 'technology', 'books', 'services', 'other']).withMessage('Categoría inválida')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        ok: false,
        message: 'Datos de entrada inválidos',
        errors: errors.array()
      });
    }

    const { title, description, price, category, condition_type, images } = req.body;

    const [result] = await pool.query(
      'INSERT INTO products (user_id, title, description, price, category, condition_type, images) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [req.user.userId, title, description, price, category, condition_type || 'used', JSON.stringify(images || [])]
    );

    res.status(201).json({
      ok: true,
      message: 'Producto creado exitosamente',
      productId: result.insertId
    });

  } catch (error) {
    console.error('Error creando producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/products/categories - Obtener categorías
router.get('/categories/list', async (req, res) => {
  try {
    const [categories] = await pool.query(
      'SELECT * FROM categories WHERE is_active = TRUE ORDER BY name'
    );

    res.json({
      ok: true,
      categories
    });

  } catch (error) {
    console.error('Error obteniendo categorías:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

module.exports = router;
