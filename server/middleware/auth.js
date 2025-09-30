const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');

// Middleware para verificar JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return next(new AppError(
      "Token de acceso requerido",
      "TOKEN_REQUIRED",
      401
    ));
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return next(new AppError(
        "Token inválido o expirado",
        "TOKEN_INVALID",
        403
      ));
    }

    req.user = user;
    next();
  });
};

// Middleware para verificar rol de admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'ADMIN') {
    return next(new AppError(
      "Acceso denegado: se requieren permisos de administrador",
      "FORBIDDEN_ADMIN",
      403,
      { requiredRole: "ADMIN" }
    ));
  }
  next();
};

// Middleware para verificar rol de vendedor o admin
const requireVendor = (req, res, next) => {
  if (!['ADMIN', 'VENDEDOR'].includes(req.user.role)) {
    return next(new AppError(
      "Acceso denegado: se requieren permisos de vendedor",
      "FORBIDDEN_VENDOR",
      403,
      { requiredRoles: ["ADMIN", "VENDEDOR"] }
    ));
  }
  next();
};

module.exports = {
  authenticateToken,
  requireAdmin,
  requireVendor
};
