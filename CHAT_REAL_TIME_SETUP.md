# Chat en Tiempo Real - Configuración

## 🚀 Funcionalidades Implementadas

### Servidor (Node.js + Socket.IO)
- ✅ WebSocket con Socket.IO para comunicación en tiempo real
- ✅ Autenticación JWT para WebSocket
- ✅ Envío de mensajes en tiempo real
- ✅ Indicadores de escritura (typing indicators)
- ✅ Notificaciones de usuarios online/offline
- ✅ Persistencia de mensajes en base de datos PostgreSQL

### Cliente (Flutter)
- ✅ Servicio WebSocket con reconexión automática
- ✅ Interfaz de chat actualizada con datos reales
- ✅ Indicadores de escritura en tiempo real
- ✅ Envío de mensajes con WebSocket
- ✅ Lista de conversaciones actualizada automáticamente
- ✅ Soporte para imágenes (enviadas como archivos)

## 📋 Archivos Modificados/Creados

### Servidor
- `server/package.json` - Agregada dependencia socket.io
- `server/server.js` - Implementado WebSocket con Socket.IO
- `server/routes/chat.js` - Endpoints REST existentes (sin cambios)

### Flutter
- `lib/services/websocket_service.dart` - Servicio WebSocket
- `lib/services/chat_service.dart` - Servicio de chat combinado (REST + WebSocket)
- `lib/widgets/chat_view.dart` - Widget de chat actualizado
- `lib/screens/chat_page.dart` - Página de chat actualizada
- `lib/screens/conversations_page.dart` - Lista de conversaciones con datos reales
- `lib/main.dart` - Inicialización del servicio de chat
- `pubspec.yaml` - Agregada dependencia socket_io_client

## 🔧 Configuración

### 1. Instalar Dependencias

```bash
# Servidor
cd server
npm install

# Flutter
flutter pub get
```

### 2. Configurar URLs

En `lib/services/websocket_service.dart` y `lib/services/chat_service.dart`, actualiza las URLs:

```dart
// Cambiar localhost por tu IP del servidor
'http://localhost:3001' // WebSocket
'http://localhost:3001/api' // API REST
```

### 3. Iniciar Servidor

```bash
cd server
npm run dev
```

### 4. Ejecutar Flutter

```bash
flutter run
```

## 🎯 Cómo Funciona

### Flujo de Mensajes
1. Usuario escribe mensaje en `ChatView`
2. Mensaje se envía via WebSocket al servidor
3. Servidor guarda mensaje en base de datos
4. Servidor reenvía mensaje al destinatario via WebSocket
5. Destinatario recibe mensaje en tiempo real

### Indicadores de Escritura
1. Usuario comienza a escribir
2. Se envía evento `typing_start` via WebSocket
3. Destinatario ve "Usuario está escribiendo..."
4. Después de 2 segundos sin escribir, se envía `typing_stop`

### Lista de Conversaciones
1. Se cargan conversaciones via API REST al abrir la página
2. Se actualiza automáticamente cuando llegan nuevos mensajes
3. Muestra último mensaje y timestamp

## 🔍 Eventos WebSocket

### Cliente → Servidor
- `send_message` - Enviar mensaje
- `typing_start` - Usuario comenzó a escribir
- `typing_stop` - Usuario dejó de escribir

### Servidor → Cliente
- `new_message` - Nuevo mensaje recibido
- `message_sent` - Confirmación de mensaje enviado
- `message_error` - Error enviando mensaje
- `user_typing` - Usuario está escribiendo
- `user_online` - Usuario conectado
- `user_offline` - Usuario desconectado

## 🐛 Solución de Problemas

### Errores de Compilación (RESUELTOS)
- ✅ **Headers HTTP**: Corregido tipo `Map<String, dynamic>` a `Map<String, String>`
- ✅ **AuthService**: Agregado método `getCurrentUser()` para compatibilidad
- ✅ **Token Storage**: Corregido key de `'auth_token'` a `'session_token'`

### WebSocket no conecta
- Verificar que el servidor esté corriendo
- Verificar URL en `websocket_service.dart`
- Verificar token de autenticación

### Mensajes no llegan
- Verificar conexión WebSocket
- Verificar que ambos usuarios estén autenticados
- Verificar logs del servidor

### Indicadores de escritura no funcionan
- Verificar que `typing_start`/`typing_stop` se envíen
- Verificar que el destinatario esté conectado

## 📱 Próximas Mejoras

- [ ] Notificaciones push para mensajes
- [ ] Mensajes de voz
- [ ] Envío de archivos
- [ ] Mensajes con reacciones
- [ ] Mensajes editados/eliminados
- [ ] Estados de entrega (enviado, entregado, leído)
- [ ] Búsqueda de mensajes
- [ ] Mensajes destacados

## 🔐 Seguridad

- Autenticación JWT requerida para WebSocket
- Validación de permisos de mensaje
- Rate limiting en endpoints REST
- CORS configurado para desarrollo

## 📊 Rendimiento

- Reconexión automática en caso de pérdida de conexión
- Mensajes persistentes en base de datos
- UI optimizada con ListView para grandes conversaciones
- Indicadores de carga durante operaciones
