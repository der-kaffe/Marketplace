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
const isDev = process.env.NODE_ENV !== 'production';

app.use('/api/chat', chatRoutes);
// CORS
// En desarrollo: reflejar cualquier Origin automáticamente.
// En producción: validar contra CORS_ORIGIN, soportando comodín al final (ej. http://localhost:*).
const rawOrigins = process.env.CORS_ORIGIN || '';
const originList = (rawOrigins || (isDev ? '*' : '')).split(',').map(o => o.trim()).filter(Boolean);

const corsOptions = isDev
  ? {
      origin: true, // refleja el origin recibido
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    }
  : {
      origin: function (origin, callback) {
        if (!origin) return callback(null, true); // Postman/mobile
        if (originList.length === 0) return callback(new Error('No permitido por CORS'));
        const isAllowed = originList.some((allowed) => {
          if (allowed === '*') return true;
          if (allowed.endsWith('*')) {
            const base = allowed.slice(0, -1);
            return origin.startsWith(base);
          }
          return origin === allowed;
        });
        return isAllowed ? callback(null, true) : callback(new Error('No permitido por CORS'));
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    };

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // preflight universal

// Middleware de seguridad
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // límite de 100 requests por ventana
  message: 'Demasiadas peticiones desde esta IP, intenta de nuevo más tarde.'
});
app.use(limiter);

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
