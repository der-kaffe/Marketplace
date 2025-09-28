require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { testConnection } = require('./config/database');

// Importar rutas
const authRoutes = require('./routes/auth-marketplace');
const userRoutes = require('./routes/users');
const productRoutes = require('./routes/products');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware de seguridad
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // límite de 100 requests por ventana
  message: 'Demasiadas peticiones desde esta IP, intenta de nuevo más tarde.'
});
app.use(limiter);

// CORS
const corsOptions = {
  origin: function (origin, callback) {
    // Permitir requests sin origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = process.env.CORS_ORIGIN.split(',');
    const isAllowed = allowedOrigins.some(allowedOrigin => {
      if (allowedOrigin.includes('*')) {
        const baseUrl = allowedOrigin.replace('*', '');
        return origin.startsWith(baseUrl);
      }
      return origin === allowedOrigin;
    });
    
    if (isAllowed) {
      callback(null, true);
    } else {
      callback(new Error('No permitido por CORS'));
    }
  },
  credentials: true
};
app.use(cors(corsOptions));

// Middleware para parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Ruta de salud
app.get('/api/health', async (req, res) => {
  try {
    const dbOk = await testConnection();
    res.json({ 
      ok: true, 
      timestamp: new Date().toISOString(),
      database: dbOk ? 'connected' : 'disconnected',
      service: 'Marketplace API',
      version: '1.0.0'
    });
  } catch (error) {
    console.error('Error en health check:', error);
    res.status(500).json({ 
      ok: false, 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Rutas de la API
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  if (err.message === 'No permitido por CORS') {
    return res.status(403).json({ error: 'CORS: Origen no permitido' });
  }
  
  res.status(500).json({ 
    error: process.env.NODE_ENV === 'development' ? err.message : 'Error interno del servidor',
    timestamp: new Date().toISOString()
  });
});

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Ruta no encontrada',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Iniciar servidor
async function startServer() {
  try {
    // Probar conexión a base de datos
    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.error('❌ No se pudo conectar a la base de datos');
      console.log('\n💡 Asegúrate de que MySQL esté corriendo y las credenciales sean correctas');
      console.log('   Revisa el archivo .env y la configuración de MySQL');
      process.exit(1);
    }
    
    app.listen(PORT, async () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
      console.log(`📊 Panel de administración: http://localhost:8080 (si usas Docker)`);
      console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
      console.log(`📝 Entorno: ${process.env.NODE_ENV}`);
        // Servidor listo para desarrollo
      console.log('🚀 Servidor marketplace listo para recibir conexiones');
    });
  } catch (error) {
    console.error('❌ Error iniciando servidor:', error);
    process.exit(1);
  }
}

startServer();
