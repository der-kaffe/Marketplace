require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { testConnection, closeConnection } = require('./config/database');

// Importar rutas
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const productRoutes = require('./routes/products');
const publicationsRoutes = require('./routes/publications');
const chatRoutes = require('./routes/chat');
const favoritesRoutes = require('./routes/favorites');

const app = express();
const PORT = process.env.PORT || 3001;

// Rutas de chat
app.use('/api/chat', chatRoutes);

// Middleware de seguridad
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // límite de 100 requests por ventana
  message: 'Demasiadas peticiones desde esta IP, intenta de nuevo más tarde.'
});
app.use(limiter);

// CORS - Configuración más permisiva para desarrollo
const corsOptions = {
  origin: function (origin, callback) {
    console.log('🌐 CORS: Petición desde origen:', origin);
    
    // Permitir requests sin origin (mobile apps, Postman, etc.)
    if (!origin) {
      console.log('✅ CORS: Permitiendo request sin origen');
      return callback(null, true);
    }
    
    // En desarrollo, permitir localhost en cualquier puerto
    if (process.env.NODE_ENV === 'development') {
      if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
        console.log('✅ CORS: Permitiendo localhost en desarrollo');
        return callback(null, true);
      }
    }
    
    // También verificar la lista específica del .env
    const allowedOrigins = process.env.CORS_ORIGIN.split(',');
    const isAllowed = allowedOrigins.some(allowedOrigin => {
      if (allowedOrigin.includes('*')) {
        const baseUrl = allowedOrigin.replace('*', '');
        return origin.startsWith(baseUrl);
      }
      return origin === allowedOrigin;
    });
    
    if (isAllowed) {
      console.log('✅ CORS: Origen permitido por configuración');
      callback(null, true);
    } else {
      console.log('❌ CORS: Origen NO permitido:', origin);
      callback(new Error(`No permitido por CORS: ${origin}`));
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
app.use('/api/publications', publicationsRoutes);
app.use('/api/favorites', favoritesRoutes);

const adminRoutes = require('./routes/admin');
app.use('/api/admin', adminRoutes);

// Middleware de manejo de errores
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: "NOT_FOUND",
      message: "Ruta no encontrada"
    },
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
      console.log('\n💡 Asegúrate de que PostgreSQL esté corriendo y las credenciales sean correctas');
      console.log('   Revisa el archivo .env y configura DATABASE_URL para PostgreSQL');
      console.log('   Ejemplo: DATABASE_URL="postgresql://username:password@localhost:5432/marketplace"');
      process.exit(1);
    }
    
    app.listen(PORT, async () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
      console.log(`🗄️  PostgreSQL con Prisma configurado`);
      console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
      console.log(`📝 Entorno: ${process.env.NODE_ENV}`);
      console.log(`🎨 Prisma Studio: npm run db:studio`);
      
      // Ejecutar tests automáticamente en desarrollo
      if (process.env.NODE_ENV === 'development') {
        setTimeout(async () => {
          try {
            const { testAPI } = require('./scripts/test-api');
            await testAPI();
          } catch (error) {
            console.log('⚠️  Test API no disponible aún');
          }
        }, 1000);
      }
    });
  } catch (error) {
    console.error('❌ Error iniciando servidor:', error);
    process.exit(1);
  }
}

// Manejo de cierre graceful
process.on('SIGINT', async () => {
  console.log('\n🔄 Cerrando servidor...');
  await closeConnection();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🔄 Cerrando servidor...');
  await closeConnection();
  process.exit(0);
});

startServer();
