// server.js
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
const path = require('path');

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
      if (!origin) return callback(null, true);
      if (process.env.NODE_ENV === 'development') {
        if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
          return callback(null, true);
        }
      }
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

// (Definir corsOptions antes de usarlo)
const corsOptions = {
  origin: function (origin, callback) {
    console.log('🌐 CORS: Petición desde origen:', origin);
    if (!origin) {
      console.log('✅ CORS: Permitiendo request sin origen');
      return callback(null, true);
    }
    if (process.env.NODE_ENV === 'development') {
      if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
        console.log('✅ CORS: Permitiendo localhost en desarrollo');
        return callback(null, true);
      }
    }
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

// Middlewares
app.use(helmet());
app.use('/api', apiLimiter);
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(auditMiddleware);
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
    res.status(500).json({ ok: false, error: error.message });
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
const connectedUsers = new Map(); // userId -> { socketId, appState }

// Middleware de autenticación para WebSocket
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Token de autenticación requerido'));
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // DEBUG: Loguear el payload del token (puedes borrar esto después)
    console.log('PAYLOAD DEL TOKEN RECIBIDO:', decoded);

    socket.userId = decoded.userId;
    socket.userName = decoded.nombre; // (Viene del token arreglado en auth.js)
    next();
  } catch (error) {
    next(new Error('Token inválido'));
  }
});

io.on('connection', (socket) => {
  const { prisma } = require('./config/database');
  console.log(`🔌 Usuario conectado: ${socket.userName} (ID: ${socket.userId})`);
  console.log(`🔌 Socket ID: ${socket.id}`);

  // MODIFICADO: Guardar socket y estado de la app
  const existingConnection = connectedUsers.get(socket.userId);
  if (existingConnection && existingConnection.socketId !== socket.id) {
    console.log(`⚠️ Usuario ${socket.userId} ya tiene una conexión activa (${existingConnection.socketId}). Desconectando socket anterior...`);
    const existingSocket = io.sockets.sockets.get(existingConnection.socketId);
    if (existingSocket) {
      existingSocket.disconnect(true);
    }
  }

  // Guardar la nueva conexión del usuario
  connectedUsers.set(socket.userId, {
    socketId: socket.id,
    appState: 'foreground' // Por defecto, la app está en primer plano
  });

  console.log(`👥 Usuarios conectados ahora:`, Array.from(connectedUsers.keys()));

  // ... (unir a salas, etc.)
  socket.join(`user_${socket.userId}`);
  const COMMUNITY_ROOM = 'room_comunidad_uct';
  socket.join(COMMUNITY_ROOM);

  socket.broadcast.emit('user_online', {
    userId: socket.userId,
    userName: socket.userName
  });

  // NUEVO: Escuchar cambios de estado de la app (foreground/background)
  socket.on('app_state', (state) => {
    if (connectedUsers.has(socket.userId)) {
      const currentState = state === 'foreground' ? 'foreground' : 'background';
      connectedUsers.get(socket.userId).appState = currentState;
      console.log(`📱 Usuario ${socket.userId} cambió su estado a: ${currentState}`);
    }
  });

  // Manejar envío de mensajes
  socket.on('send_message', async (data) => {
    try {
      console.log('📨 Evento send_message recibido:', data);
      console.log('👤 Usuario remitente:', socket.userId, socket.userName);

      const { destinatarioId, contenido, tipo = 'texto' } = data;
      const destinatarioIdInt = parseInt(destinatarioId);

      if (!destinatarioIdInt || !contenido) {
        return socket.emit('message_error', { error: 'Datos incompletos' });
      }
      if (destinatarioIdInt === socket.userId) {
        return socket.emit('message_error', { error: 'No puedes enviarte mensajes a ti mismo' });
      }

      // Guardar mensaje en la base de datos
      const mensaje = await prisma.Mensajes.create({
        data: {
          remitenteId: socket.userId,
          destinatarioId: destinatarioIdInt,
          contenido,
          tipo: tipo || 'texto'
        },
        include: {
          remitente: { select: { id: true, nombre: true, usuario: true } },
          destinatario: { select: { id: true, nombre: true, usuario: true } }
        }
      });
      console.log('💾 Mensaje guardado en BD:', mensaje.id);

      // MODIFICADO: Lógica de envío (Socket vs Push)
      const recipientInfo = connectedUsers.get(destinatarioIdInt);
      let destinatarioConectado = false;
      let enviarPorSocket = false;

      if (recipientInfo && recipientInfo.socketId) {
        destinatarioConectado = true;
        // Solo envía por socket si está conectado Y en primer plano
        if (recipientInfo.appState === 'foreground') {
          enviarPorSocket = true;
        }
      }

      if (destinatarioConectado && enviarPorSocket) {
        // --- EL USUARIO ESTÁ CONECTADO Y VIENDO LA APP ---
        const destinatarioSocket = io.sockets.sockets.get(recipientInfo.socketId);
        if (destinatarioSocket && destinatarioSocket.connected) {
          console.log(`✅ Enviando mensaje a destinatario CONECTADO y EN PRIMER PLANO (Socket)`);
          io.to(recipientInfo.socketId).emit('new_message', mensaje);
        }
      } else {
        // --- EL USUARIO ESTÁ OFFLINE O EN SEGUNDO PLANO ---
        if (destinatarioConectado) {
          console.log(`⚠️ Destinatario ${destinatarioIdInt} está conectado pero en SEGUNDO PLANO. Enviando Push Notification.`);
        } else {
          console.log(`⚠️ Destinatario ${destinatarioIdInt} está DESCONECTADO. Enviando Push Notification.`);
        }

        // ⭐️ INICIO: Enviar Notificación Push (Lógica ya corregida) ⭐️
        try {
          const destinatario = await prisma.cuentas.findUnique({
            where: { id: destinatarioIdInt },
            select: { fcm_token: true }
          });

          if (destinatario && destinatario.fcm_token) {
            console.log(`🔔 Enviando notificación de CHAT a ${destinatario.fcm_token}`);

            let notificationBody;
            if (tipo === 'imagen') {
              notificationBody = 'Te ha enviado una imagen 📷';
            } else {
              notificationBody = contenido; // El mensaje de texto normal
            }

            await admin.messaging().send({
              token: destinatario.fcm_token,
              notification: {
                title: `Nuevo mensaje de ${socket.userName || 'un usuario'} 💬`,
                body: notificationBody
              },
              data: {
                screen: 'chat',
                senderId: socket.userId.toString()
              }
            });
          }
        } catch (fcmError) {
          console.error("❌ Error al enviar notificación FCM de chat:", fcmError);
        }
        // ⭐️ FIN: Enviar Notificación Push ⭐️
      }

      // Confirmar envío al remitente
      socket.emit('message_sent', mensaje);
      console.log(`✅ Confirmación enviada al remitente: ${socket.userId}`);

    } catch (error) {
      console.error('❌ Error enviando mensaje:', error);
      socket.emit('message_error', { error: 'Error enviando mensaje' });
    }
  });

  // Manejar envío de mensajes al chat de la comunidad
  socket.on('send_group_message', async (data) => {
    try {
      const { contenido, tipo = 'texto' } = data || {};

      if (!contenido) {
        socket.emit('group_message_error', { error: 'Contenido requerido' });
        return;
      }

      const registro = await prisma.ComunidadMensajes.create({
        data: {
          usuarioId: socket.userId,
          contenido,
          tipo: tipo || 'texto'
        },
        include: {
          usuario: { select: { id: true, nombre: true, usuario: true } }
        }
      });

      const mensaje = {
        id: registro.id,
        contenido: registro.contenido,
        tipo: registro.tipo,
        remitenteId: registro.usuarioId,
        remitente: {
          id: registro.usuario.id,
          nombre: registro.usuario.nombre,
          usuario: registro.usuario.usuario
        },
        fechaEnvio: registro.fechaEnvio,
        room: COMMUNITY_ROOM
      };

      io.to(COMMUNITY_ROOM).emit('group_new_message', mensaje);
      socket.emit('group_message_sent', mensaje);
    } catch (error) {
      console.error('❌ Error enviando mensaje de comunidad:', error);
      socket.emit('group_message_error', { error: 'Error enviando mensaje de comunidad' });
    }
  });

  // Manejar typing indicators
  socket.on('typing_start', (data) => {
    const { destinatarioId } = data;
    const recipientInfo = connectedUsers.get(parseInt(destinatarioId));
    if (recipientInfo && recipientInfo.socketId) {
      io.to(recipientInfo.socketId).emit('user_typing', {
        userId: socket.userId,
        userName: socket.userName,
        isTyping: true
      });
    }
  });

  socket.on('typing_stop', (data) => {
    const { destinatarioId } = data;
    const recipientInfo = connectedUsers.get(parseInt(destinatarioId));
    if (recipientInfo && recipientInfo.socketId) {
      io.to(recipientInfo.socketId).emit('user_typing', {
        userId: socket.userId,
        userName: socket.userName,
        isTyping: false
      });
    }
  });

  // Manejar desconexión
  socket.on('disconnect', (reason) => {
    console.log(`🔌 Usuario desconectado: ${socket.userName} (ID: ${socket.userId})`);
    console.log(`🔌 Razón de desconexión: ${reason}`);

    // MODIFICADO: Comprobar el socketId antes de borrar
    const currentConnection = connectedUsers.get(socket.userId);
    if (currentConnection && currentConnection.socketId === socket.id) {
      connectedUsers.delete(socket.userId);
      console.log(`✅ Socket ${socket.id} eliminado del mapa de conexiones`);
    } else {
      console.log(`⚠️ Socket ${socket.id} no estaba en el mapa (actual: ${currentConnection?.socketId})`);
    }

    console.log(`👥 Usuarios conectados después de desconexión:`, Array.from(connectedUsers.keys()));

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
    path: req.originalUrl
  });
});

// Iniciar servidor
async function startServer() {
  try {
    await testConnection();
    console.log('✅ Conexión a PostgreSQL establecida correctamente');

    server.listen(PORT, async () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
      console.log(`📝 Entorno: ${process.env.NODE_ENV}`);
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