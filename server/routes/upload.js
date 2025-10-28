const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Configurar multer para subir imágenes
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/chat');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'chat-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB límite
  },
  fileFilter: function (req, file, cb) {
    // Solo permitir imágenes
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Solo se permiten archivos de imagen'), false);
    }
  }
});

// Configuración para imágenes de productos
const storageProductos = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/productos');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'producto-' + uniqueSuffix + path.extname(file.originalname));
  }
});
const uploadProductos = multer({
  storage: storageProductos,
  limits: upload.limits,
  fileFilter: upload.fileFilter
});

// 📸 Subir imagen de chat
router.post('/upload-image', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ ok: false, message: 'No se proporcionó imagen' });
    }

    // Crear URL pública para la imagen
    const imageUrl = `/uploads/chat/${req.file.filename}`;
    
    console.log('📸 Imagen subida:', {
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      url: imageUrl
    });

    res.json({ 
      ok: true, 
      imageUrl: imageUrl,
      filename: req.file.filename 
    });
  } catch (error) {
    console.error('Error subiendo imagen:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// 📦 Subida de imagen para productos (sin autenticación, para compatibilidad Flutter)
router.post('/', (req, res, next) => {
  upload.single('image')(req, res, function (err) {
    if (err instanceof multer.MulterError) {
      // Error de Multer
      return res.status(400).json({ ok: false, error: err.message });
    } else if (err) {
      // Otro error (por ejemplo, filtro de tipo)
      return res.status(400).json({ ok: false, error: err.message });
    }
    if (!req.file) {
      return res.status(400).json({ ok: false, error: 'No se envió ninguna imagen.' });
    }
    // Construye la URL pública absoluta
    const protocol = req.protocol;
    const host = req.get('host');
    const imageUrl = `${protocol}://${host}/uploads/chat/${req.file.filename}`;
    res.json({ ok: true, imageUrl });
  });
});

// 📦 Subida de imagen para productos (carpeta productos)
router.post('/producto', (req, res, next) => {
  uploadProductos.single('image')(req, res, function (err) {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ ok: false, error: err.message });
    } else if (err) {
      return res.status(400).json({ ok: false, error: err.message });
    }
    if (!req.file) {
      return res.status(400).json({ ok: false, error: 'No se envió ninguna imagen.' });
    }
    const protocol = req.protocol;
    const host = req.get('host');
    const imageUrl = `${protocol}://${host}/uploads/productos/${req.file.filename}`;
    res.json({ ok: true, imageUrl });
  });
});

// 📁 Servir archivos estáticos de uploads
router.use('/uploads', express.static(path.join(__dirname, '../uploads')));

module.exports = router;
