const jwt = require('jsonwebtoken');

// Middleware para verificar JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      ok: false,
      message: 'Token de acceso requerido'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        ok: false,
        message: 'Token inválido o expirado'
      });
    }
    
    req.user = user;
    next();
  });
};

// Middleware para verificar rol de admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({
      ok: false,
      message: 'Acceso denegado: se requieren permisos de administrador'
    });
  }
  next();
};

// Middleware para verificar rol de vendedor o admin
const requireVendor = (req, res, next) => {
  if (!['ADMIN', 'VENDEDOR'].includes(req.user.role)) {
    return res.status(403).json({
      ok: false,
      message: 'Acceso denegado: se requieren permisos de vendedor'
    });
  }
  next();
};

module.exports = {
  authenticateToken,
  requireAdmin,
  requireVendor
};
