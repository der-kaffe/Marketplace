// middleware/rateLimiters.js
const rateLimit = require('express-rate-limit');

// Rate limiter para login - más restrictivo
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 5, // máximo 5 intentos por IP
  message: {
    ok: false,
    message: 'Demasiados intentos de login. Intenta de nuevo en 15 minutos.',
    code: 'TOO_MANY_LOGIN_ATTEMPTS'
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Incrementar el contador solo en fallos de login
  skipSuccessfulRequests: true,
});

// Rate limiter para registro
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hora
  max: 3, // máximo 3 registros por IP por hora
  message: {
    ok: false,
    message: 'Demasiados intentos de registro. Intenta de nuevo en 1 hora.',
    code: 'TOO_MANY_REGISTER_ATTEMPTS'
  },
});

// Rate limiter para API general
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // 100 requests por ventana
  message: {
    ok: false,
    message: 'Demasiadas peticiones. Intenta de nuevo más tarde.',
    code: 'RATE_LIMIT_EXCEEDED'
  },
});

// Rate limiter para uploads
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hora
  max: 20, // máximo 20 uploads por hora
  message: {
    ok: false,
    message: 'Demasiadas subidas de archivos. Intenta de nuevo en 1 hora.',
    code: 'TOO_MANY_UPLOADS'
  },
});

module.exports = {
  loginLimiter,
  registerLimiter,
  apiLimiter,
  uploadLimiter
};
