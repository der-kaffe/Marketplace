// middleware/secureLogger.js
const fs = require('fs');
const path = require('path');

// Crear directorio de logs si no existe
const logsDir = path.join(__dirname, '..', 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Función para filtrar datos sensibles
const filterSensitiveData = (obj) => {
  if (typeof obj !== 'object' || obj === null) return obj;
  
  const filtered = { ...obj };
  const sensitiveFields = ['password', 'token', 'authorization', 'contrasena', 'jwt'];
  
  for (const key in filtered) {
    if (sensitiveFields.some(field => key.toLowerCase().includes(field))) {
      filtered[key] = '[FILTERED]';
    } else if (typeof filtered[key] === 'object') {
      filtered[key] = filterSensitiveData(filtered[key]);
    }
  }
  
  return filtered;
};

// Logger personalizado
const secureLog = {
  info: (message, meta = {}) => {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: 'INFO',
      message,
      ...filterSensitiveData(meta)
    };
    
    console.log(`[INFO] ${logEntry.timestamp}: ${message}`);
    
    if (process.env.NODE_ENV === 'production') {
      fs.appendFileSync(
        path.join(logsDir, 'app.log'),
        JSON.stringify(logEntry) + '\n'
      );
    }
  },

  error: (message, error = null, meta = {}) => {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: 'ERROR',
      message,
      error: error ? {
        message: error.message,
        stack: error.stack,
        code: error.code
      } : null,
      ...filterSensitiveData(meta)
    };
    
    console.error(`[ERROR] ${logEntry.timestamp}: ${message}`, error);
    
    if (process.env.NODE_ENV === 'production') {
      fs.appendFileSync(
        path.join(logsDir, 'error.log'),
        JSON.stringify(logEntry) + '\n'
      );
    }
  },

  warn: (message, meta = {}) => {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: 'WARN',
      message,
      ...filterSensitiveData(meta)
    };
    
    console.warn(`[WARN] ${logEntry.timestamp}: ${message}`);
    
    if (process.env.NODE_ENV === 'production') {
      fs.appendFileSync(
        path.join(logsDir, 'app.log'),
        JSON.stringify(logEntry) + '\n'
      );
    }
  }
};

// Middleware de auditoría para requests
const auditMiddleware = (req, res, next) => {
  const startTime = Date.now();
  const originalSend = res.send;
  
  res.send = function(data) {
    const duration = Date.now() - startTime;
    
    // Log solo información no sensible
    secureLog.info('API Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      userId: req.user?.userId || 'anonymous',
      userRole: req.user?.role || 'none'
    });
    
    return originalSend.call(this, data);
  };
  
  next();
};

module.exports = {
  secureLog,
  auditMiddleware
};
