// server,js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { testConnection, closeConnection } = require('./config/database');
const admin = require('firebase-admin');
const path = require('path'); // Asegúrate de tener esto arriba

// Importar rutas
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const productRoutes = require('./routes/products');
const publicationsRoutes = require('./routes/publications');
const chatRoutes = require('./routes/chat');
const uploadRoutes = require('./routes/upload');
const favoritesRoutes = require('./routes/favorites');
const reportsRoutes = require('./routes/reports');
const transactionRoutes = require('./routes/transactions');
const { apiLimiter, uploadLimiter } = require('./middleware/rateLimiters');
const { secureLog, auditMiddleware } = require('./middleware/secureLogger');


try {
  const serviceAccount = require('./config/firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin SDK inicializado.');
} catch (error) {
  console.error('❌ Error inicializando Firebase Admin SDK:', error.message);
}

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: function (origin, callback) {
      // Permitir requests sin origin (mobile apps)
      if (!origin) return callback(null, true);

      // En desarrollo, permitir localhost en cualquier puerto
      if (process.env.NODE_ENV === 'development') {
        if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
          return callback(null, true);
        }
      }

      // Verificar la lista específica del .env
      const allowedOrigins = process.env.CORS_ORIGIN.split(',');
      const isAllowed = allowedOrigins.some(allowedOrigin => {
        if (allowedOrigin.includes('*')) {
          const baseUrl = allowedOrigin.replace('*', '');
          return origin.startsWith(baseUrl);
        }
        return origin === allowedOrigin;
      });

      callback(null, isAllowed);
    },
    credentials: true
  }
});

const PORT = process.env.PORT || 3001;

// Middleware de seguridad
app.use(helmet());

// Rate limiting - Aplicar limiter general para todas las rutas API
app.use('/api', apiLimiter);

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

// 🔒 Middleware de auditoría (antes de las rutas)
app.use(auditMiddleware);

// Servir archivos estáticos de uploads para acceso público
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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
app.use('/api/chat', chatRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/transactions', transactionRoutes);

const adminRoutes = require('./routes/admin');
app.use('/api/admin', adminRoutes);

app.use('/api/reports', reportsRoutes);

// WebSocket para chat en tiempo real
const connectedUsers = new Map(); // userId -> socketId

// Middleware de autenticación para WebSocket
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Token de autenticación requerido'));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    socket.userName = decoded.nombre;
    next();
  } catch (error) {
    next(new Error('Token inválido'));
  }
});

io.on('connection', (socket) => {
  const { prisma } = require('./config/database');
  console.log(`🔌 Usuario conectado: ${socket.userName} (ID: ${socket.userId})`);
  console.log(`🔌 Socket ID: ${socket.id}`);

  // Guardar la conexión del usuario
  connectedUsers.set(socket.userId, socket.id);

  console.log(`👥 Usuarios conectados ahora:`, Array.from(connectedUsers.keys()));
  console.log(`📋 Map de conexiones:`, Object.fromEntries(connectedUsers));

  // Unir al usuario a una sala personal
  socket.join(`user_${socket.userId}`);

  // Notificar a otros usuarios que este usuario está online
  socket.broadcast.emit('user_online', {
    userId: socket.userId,
    userName: socket.userName
  });

  // Manejar envío de mensajes
  socket.on('send_message', async (data) => {
    try {
      console.log('📨 Evento send_message recibido:', data);
      console.log('👤 Usuario remitente:', socket.userId, socket.userName);

      const { destinatarioId, contenido, tipo = 'texto' } = data;

      if (!destinatarioId || !contenido) {
        console.log('❌ Datos incompletos:', { destinatarioId, contenido });
        socket.emit('message_error', { error: 'Datos incompletos' });
        return;
      }

      // Guardar mensaje en la base de datos
      const mensaje = await prisma.Mensajes.create({
        data: {
          remitenteId: socket.userId,
          destinatarioId: parseInt(destinatarioId),
          contenido,
          tipo: tipo || 'texto'
        },
        include: {
          remitente: { select: { id: true, nombre: true, usuario: true } },
          destinatario: { select: { id: true, nombre: true, usuario: true } }
        }
      });

      console.log('💾 Mensaje guardado en BD:', mensaje.id);

      // Enviar mensaje al destinatario si está conectado
      const destinatarioIdInt = parseInt(destinatarioId);
      const destinatarioSocketId = connectedUsers.get(destinatarioIdInt);

      if (destinatarioSocketId) {
        // --- EL USUARIO ESTÁ CONECTADO ---
        console.log(`✅ Enviando mensaje a destinatario conectado: ${destinatarioSocketId}`);
        io.to(destinatarioSocketId).emit('new_message', mensaje);

      } else {
        // --- EL USUARIO ESTÁ DESCONECTADO (ENVIAR PUSH) ---
        console.log(`⚠️ Destinatario ${destinatarioId} no está conectado. Enviando Push Notification.`);

        // ⭐️ INICIO: Enviar Notificación Push de CHAT ⭐️
        try {
          // 1. Busca el token FCM del destinatario
          const destinatario = await prisma.cuentas.findUnique({
            where: { id: destinatarioIdInt },
            select: { fcm_token: true }
          });

          // 2. Si tiene token, envía la notificación
          if (destinatario && destinatario.fcm_token) {
            console.log(`🔔 Enviando notificación de CHAT a ${destinatario.fcm_token}`);
            await admin.messaging().send({
              token: destinatario.fcm_token,
              notification: {
                title: `Nuevo mensaje de ${socket.userName} 💬`, // socket.userName viene del middleware
                body: contenido
              },
              data: {
                screen: 'chat', // Para abrir la pantalla de chat
                senderId: socket.userId.toString() // socket.userId viene del middleware
              }
            });
          }
        } catch (fcmError) {
          console.error("❌ Error al enviar notificación FCM de chat:", fcmError);
        }
        // ⭐️ FIN: Enviar Notificación Push de CHAT ⭐️
      }

      // Confirmar envío al remitente
      socket.emit('message_sent', mensaje);
      console.log(`✅ Confirmación enviada al remitente: ${socket.userId}`);

    } catch (error) {
      console.error('❌ Error enviando mensaje:', error);
      socket.emit('message_error', { error: 'Error enviando mensaje' });
    }
  });

  // Manejar typing indicators
  socket.on('typing_start', (data) => {
    const { destinatarioId } = data;
    const destinatarioSocketId = connectedUsers.get(parseInt(destinatarioId));
    if (destinatarioSocketId) {
      io.to(destinatarioSocketId).emit('user_typing', {
        userId: socket.userId,
        userName: socket.userName,
        isTyping: true
      });
    }
  });

  socket.on('typing_stop', (data) => {
    const { destinatarioId } = data;
    const destinatarioSocketId = connectedUsers.get(parseInt(destinatarioId));
    if (destinatarioSocketId) {
      io.to(destinatarioSocketId).emit('user_typing', {
        userId: socket.userId,
        userName: socket.userName,
        isTyping: false
      });
    }
  });

  // Manejar desconexión
  socket.on('disconnect', () => {
    console.log(`🔌 Usuario desconectado: ${socket.userName} (ID: ${socket.userId})`);
    connectedUsers.delete(socket.userId);

    // Notificar a otros usuarios que este usuario está offline
    socket.broadcast.emit('user_offline', {
      userId: socket.userId,
      userName: socket.userName
    });
  });
});

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

    server.listen(PORT, async () => {
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
