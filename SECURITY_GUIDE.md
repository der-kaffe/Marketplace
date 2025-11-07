# 🔒 Guía de Seguridad - Marketplace UCT

## 🚨 Vulnerabilidades Críticas Identificadas

### 1. **JWT Secret Débil** 
**Estado:** ❌ CRÍTICO
- **Problema:** JWT_SECRET actual es predecible y débil
- **Riesgo:** Tokens pueden ser falsificados
- **Solución:** Generar secret criptográficamente seguro

### 2. **Logs Sensibles**
**Estado:** ❌ ALTO RIESGO  
- **Problema:** Tokens se imprimen en console.log
- **Riesgo:** Exposición en logs de producción
- **Ubicación:** `middleware/auth.js:24`

### 3. **Configuración CORS Permisiva**
**Estado:** ⚠️ MEDIO RIESGO
- **Problema:** Permitir localhost en cualquier puerto en desarrollo
- **Riesgo:** Ataques desde sitios maliciosos locales

### 4. **Sin Refresh Tokens**
**Estado:** ⚠️ MEDIO RIESGO
- **Problema:** Tokens de larga duración (7 días)
- **Riesgo:** Mayor ventana de compromiso si se filtra un token

## 🛡️ Implementación de Mejoras de Seguridad

### 1. Variables de Entorno Seguras

#### JWT Secrets Fuertes
```env
# Generar con: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567890
JWT_REFRESH_SECRET=1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5f6789012345678

# Tiempos de expiración más seguros
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

#### Configuración de Producción
```env
NODE_ENV=production
BCRYPT_ROUNDS=12
RATE_LIMIT_MAX=50
RATE_LIMIT_WINDOW_MS=900000
```

### 2. Headers de Seguridad HTTP

```javascript
// Configuración de Helmet mejorada
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

### 3. Rate Limiting por Endpoint

```javascript
// Rate limiting específico por endpoint
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 5, // máximo 5 intentos de login
  message: 'Demasiados intentos de login, intenta en 15 minutos',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/auth/login', authLimiter);
```

### 4. Validación y Sanitización

```javascript
// Validación mejorada
const { body, validationResult, sanitizeBody } = require('express-validator');

const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .isLength({ max: 100 })
    .matches(/^[a-zA-Z0-9._%+-]+@(uct\.cl|alu\.uct\.cl)$/)
    .withMessage('Solo correos institucionales @uct.cl o @alu.uct.cl'),
  
  body('password')
    .isLength({ min: 8, max: 128 })
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password debe tener 8+ caracteres, mayúscula, minúscula, número y símbolo'),
  
  body('nombre')
    .trim()
    .isLength({ min: 2, max: 50 })
    .matches(/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/)
    .withMessage('Nombre solo debe contener letras y espacios'),
];
```

## 🔐 Implementación de Refresh Tokens

### Backend: Nuevos Endpoints

```javascript
// Generar tokens con refresh
const generateTokens = (payload) => {
  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
};

// Endpoint refresh token
router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(401).json({ ok: false, message: 'Refresh token requerido' });
  }

  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const { accessToken, refreshToken: newRefreshToken } = generateTokens({
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role
    });

    res.json({
      ok: true,
      accessToken,
      refreshToken: newRefreshToken
    });
  } catch (error) {
    res.status(403).json({ ok: false, message: 'Refresh token inválido' });
  }
});
```

### Frontend: Auto-renovación de Tokens

```dart
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  // Interceptor para renovar tokens automáticamente
  Future<String?> getValidAccessToken() async {
    String? accessToken = await _storage.read(key: _accessTokenKey);
    
    if (accessToken != null && !_isTokenExpired(accessToken)) {
      return accessToken;
    }
    
    // Token expirado, intentar renovar
    return await _refreshAccessToken();
  }
  
  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        body: json.encode({'refreshToken': refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
        return data['accessToken'];
      }
    } catch (e) {
      // Refresh falló, redirigir a login
      await _clearTokens();
    }
    return null;
  }
}
```

## 📊 Logging y Monitoreo Seguro

### 1. Logger sin Datos Sensibles

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format((info) => {
      // Filtrar datos sensibles
      if (info.message && typeof info.message === 'string') {
        info.message = info.message.replace(/password.*$/gi, 'password: [FILTERED]');
        info.message = info.message.replace(/token.*$/gi, 'token: [FILTERED]');
      }
      return info;
    })()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### 2. Middleware de Auditoría

```javascript
const auditMiddleware = (req, res, next) => {
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    logger.info('API Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      userId: req.user?.userId || 'anonymous'
    });
  });
  
  next();
};
```

## 🚫 Validación de Entrada Avanzada

### 1. Sanitización de Datos

```javascript
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss');

// Middleware anti NoSQL injection
app.use(mongoSanitize());

// Función para limpiar XSS
const cleanXSS = (text) => {
  return xss(text, {
    whiteList: {}, // No permitir HTML
    stripIgnoreTag: true,
    stripIgnoreTagBody: ['script']
  });
};
```

### 2. Validación de Archivos

```javascript
const multer = require('multer');
const path = require('path');

const fileFilter = (req, file, cb) => {
  // Validar tipo MIME real
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
  
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Tipo de archivo no permitido'), false);
  }
};

const upload = multer({
  dest: 'uploads/',
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB máximo
    files: 1
  },
  fileFilter
});
```

## 🔍 Checklist de Seguridad

### ✅ Implementado
- [x] Helmet para headers de seguridad
- [x] Rate limiting básico
- [x] CORS configurado
- [x] Bcrypt para passwords (rounds: 12)
- [x] JWT para autenticación
- [x] Validación de entrada básica
- [x] Flutter Secure Storage

### ❌ Pendiente de Implementar
- [ ] Refresh tokens
- [ ] JWT secrets fuertes
- [ ] Logging sin datos sensibles
- [ ] Rate limiting por endpoint
- [ ] Validación de passwords robusta
- [ ] Monitoreo de intentos fallidos
- [ ] Blacklist de tokens comprometidos
- [ ] Encriptación de datos sensibles en BD
- [ ] Auditoría de accesos
- [ ] Backup seguro de base de datos

## 🚀 Plan de Implementación Prioritario

### Fase 1: Crítico (Implementar HOY)
1. Generar JWT secret fuerte
2. Remover logs de tokens
3. Implementar refresh tokens
4. Rate limiting para login

### Fase 2: Alto (Esta semana)
1. Validación robusta de passwords
2. Logging seguro
3. Monitoreo de intentos fallidos
4. Headers de seguridad avanzados

### Fase 3: Medio (Próximo sprint)
1. Auditoría completa
2. Encriptación de datos PII
3. Backup automático seguro
4. Testing de penetración

## 📞 Contacto de Seguridad

Para reportar vulnerabilidades:
- 🔐 Email: security@marketplace-uct.cl
- 🛡️ Proceso: Responsible disclosure
- ⚡ SLA: Respuesta en 24h para críticos
