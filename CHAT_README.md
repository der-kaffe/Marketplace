# 💬 Sistema de Chat en Tiempo Real - Guía para Desarrolladores

## 📋 Índice
- [Descripción General](#descripción-general)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Componentes Principales](#componentes-principales)
- [Configuración y Setup](#configuración-y-setup)
- [API y Endpoints](#api-y-endpoints)
- [WebSocket Events](#websocket-events)
- [Flujo de Datos](#flujo-de-datos)
- [Manejo de Errores](#manejo-de-errores)
- [Testing y Debugging](#testing-y-debugging)
- [Troubleshooting](#troubleshooting)
- [Mejores Prácticas](#mejores-prácticas)

## 🎯 Descripción General

El sistema de chat implementa comunicación en tiempo real entre usuarios utilizando WebSockets (Socket.IO) con fallback a API REST. Incluye funcionalidades como:

- ✅ Mensajes de texto en tiempo real
- ✅ Envío de imágenes (URL y Base64)
- ✅ Indicadores de escritura (typing indicators)
- ✅ Notificaciones de conexión/desconexión
- ✅ Marcado de mensajes como leídos
- ✅ Persistencia en base de datos PostgreSQL
- ✅ Reconexión automática
- ✅ Manejo de errores robusto

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    WebSocket     ┌─────────────────┐
│   Flutter App   │◄────────────────►│   Node.js API   │
│                 │                  │   + Socket.IO   │
└─────────────────┘                  └─────────────────┘
         │                                      │
         │ REST API                             │
         ▼                                      ▼
┌─────────────────┐                  ┌─────────────────┐
│  ChatService    │                  │   PostgreSQL    │
│  WebSocketSvc   │                  │   Database      │
└─────────────────┘                  └─────────────────┘
```

## 📁 Componentes Principales

### Frontend (Flutter)

#### 1. **ChatService** (`lib/services/chat_service.dart`)
- **Propósito**: Servicio principal que coordina WebSocket y API REST
- **Responsabilidades**:
  - Inicialización y gestión de conexión WebSocket
  - Envío de mensajes (WebSocket con fallback a REST)
  - Obtención de conversaciones y mensajes
  - Formateo de datos para la UI
  - Marcado de mensajes como leídos

#### 2. **WebSocketService** (`lib/services/websocket_service.dart`)
- **Propósito**: Manejo directo de la conexión WebSocket
- **Responsabilidades**:
  - Conexión y desconexión del WebSocket
  - Escucha de eventos en tiempo real
  - Reconexión automática
  - Emisión de eventos al servidor

#### 3. **ChatView** (`lib/widgets/chat_view.dart`)
- **Propósito**: Widget principal de la interfaz de chat
- **Responsabilidades**:
  - Renderizado de mensajes
  - Manejo de entrada de texto
  - Envío de imágenes
  - Indicadores de escritura
  - Scroll automático

#### 4. **ConversationsPage** (`lib/screens/conversations_page.dart`)
- **Propósito**: Lista de conversaciones del usuario
- **Responsabilidades**:
  - Mostrar lista de conversaciones
  - Actualización en tiempo real
  - Navegación a chats individuales
  - Marcado de mensajes como leídos

#### 5. **ChatPage** (`lib/screens/chat_page.dart`)
- **Propósito**: Pantalla contenedora del chat
- **Responsabilidades**:
  - Header con información del destinatario
  - Contenedor para ChatView
  - Navegación de regreso

### Backend (Node.js)

#### 1. **WebSocket Server** (`server/server.js`)
- **Propósito**: Servidor Socket.IO para comunicación en tiempo real
- **Responsabilidades**:
  - Autenticación JWT para WebSocket
  - Broadcasting de mensajes
  - Manejo de indicadores de escritura
  - Gestión de usuarios online/offline

#### 2. **Chat Routes** (`server/routes/chat.js`)
- **Propósito**: Endpoints REST para funcionalidades de chat
- **Endpoints**:
  - `GET /chat/conversaciones` - Obtener conversaciones
  - `GET /chat/conversacion/:id` - Obtener mensajes de una conversación
  - `POST /chat/send` - Enviar mensaje (fallback)
  - `POST /chat/conversacion/:id/mark-read` - Marcar como leído

## ⚙️ Configuración y Setup

### 1. Dependencias del Servidor
```bash
cd server
npm install socket.io
```

### 2. Dependencias de Flutter
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.4
```

### 3. Configuración de URLs
En `lib/services/network_config.dart`:
```dart
class NetworkConfig {
  static const String baseUrl = 'http://localhost:3001/api';
  static const String websocketUrl = 'http://localhost:3001';
}
```

### 4. Inicialización del Servicio
En `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await ChatService().initialize();
  
  runApp(MyApp());
}
```

## 🔌 API y Endpoints

### REST API

#### Obtener Conversaciones
```http
GET /api/chat/conversaciones
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
  "ok": true,
  "conversaciones": [
    {
      "usuario": {
        "id": 1,
        "nombre": "Juan Pérez",
        "usuario": "juan123"
      },
      "ultimoMensaje": {
        "id": 1,
        "contenido": "Hola, ¿cómo estás?",
        "fechaEnvio": "2024-01-15T10:30:00Z",
        "remitenteId": 1
      },
      "unreadCount": 2
    }
  ]
}
```

#### Obtener Mensajes de Conversación
```http
GET /api/chat/conversacion/:usuarioId
Authorization: Bearer <token>
```

#### Enviar Mensaje (Fallback)
```http
POST /api/chat/send
Authorization: Bearer <token>
Content-Type: application/json

{
  "destinatarioId": 2,
  "contenido": "Hola mundo"
}
```

#### Marcar Mensajes como Leídos
```http
POST /api/chat/conversacion/:usuarioId/mark-read
Authorization: Bearer <token>
```

## 📡 WebSocket Events

### Eventos del Cliente al Servidor

#### Enviar Mensaje
```javascript
socket.emit('send_message', {
  destinatarioId: 2,
  contenido: 'Hola mundo',
  tipo: 'texto'
});
```

#### Indicador de Escritura
```javascript
// Iniciar escritura
socket.emit('typing_start', { destinatarioId: 2 });

// Detener escritura
socket.emit('typing_stop', { destinatarioId: 2 });
```

### Eventos del Servidor al Cliente

#### Nuevo Mensaje
```javascript
socket.on('new_message', (data) => {
  // data contiene: id, contenido, remitenteId, destinatarioId, fechaEnvio, tipo
});
```

#### Confirmación de Envío
```javascript
socket.on('message_sent', (data) => {
  // Confirmación de que el mensaje fue enviado exitosamente
});
```

#### Indicador de Escritura
```javascript
socket.on('user_typing', (data) => {
  // data: { userId, isTyping, destinatarioId }
});
```

#### Estado de Conexión
```javascript
socket.on('connect', () => {
  // WebSocket conectado
});

socket.on('disconnect', (reason) => {
  // WebSocket desconectado
});
```

## 🔄 Flujo de Datos

### 1. Inicialización del Chat
```
1. Usuario abre conversación
2. ChatService.initialize() se ejecuta
3. WebSocketService.connect() establece conexión
4. Se cargan mensajes históricos via REST API
5. Se configuran listeners para eventos en tiempo real
```

### 2. Envío de Mensaje
```
1. Usuario escribe y envía mensaje
2. ChatView._sendText() se ejecuta
3. Se crea mensaje temporal en UI
4. ChatService.sendMessage() intenta WebSocket
5. Si WebSocket falla, usa REST API como fallback
6. Servidor procesa y almacena mensaje
7. Servidor emite evento 'new_message' a destinatario
8. UI actualiza con mensaje real (reemplaza temporal)
```

### 3. Recepción de Mensaje
```
1. WebSocket recibe evento 'new_message'
2. WebSocketService emite al stream
3. ChatView escucha el stream
4. Se verifica que el mensaje es de la conversación actual
5. Se formatea y agrega a la lista de mensajes
6. UI se actualiza automáticamente
```

## ⚠️ Manejo de Errores

### 1. Errores de Conexión WebSocket
- **Detección**: `connectionStream` emite `false`
- **Acción**: Mostrar notificación al usuario
- **Recuperación**: Reconexión automática cada 1.5-30 segundos

### 2. Errores de Envío de Mensaje
- **Detección**: WebSocket no conectado o timeout
- **Acción**: Fallback automático a REST API
- **UI**: Remover mensaje temporal si falla completamente

### 3. Errores de Carga de Imágenes
- **Detección**: Fallo en `ImageUploadService`
- **Acción**: Fallback a Base64
- **UI**: Mostrar error específico al usuario

### 4. Errores de Autenticación
- **Detección**: Token inválido o expirado
- **Acción**: Redirigir a login
- **UI**: Mostrar mensaje de sesión expirada

## 🧪 Testing y Debugging

### 1. Logs de Debug
El sistema incluye logs detallados para debugging:
- Conexión WebSocket
- Envío/recepción de mensajes
- Errores de autenticación
- Fallbacks de API

### 2. Testing de Conexión
```dart
// Verificar estado de conexión
bool isConnected = ChatService().isConnected;

// Forzar reconexión
await WebSocketService().forceReconnect();
```

### 3. Testing de Mensajes
```dart
// Enviar mensaje de prueba
await ChatService().sendMessage(
  destinatarioId: 1,
  contenido: 'Mensaje de prueba'
);
```

## 🔧 Troubleshooting

### Problema: WebSocket no se conecta
**Causas posibles:**
- Token de autenticación inválido
- URL incorrecta en NetworkConfig
- Servidor no está ejecutándose
- Problemas de red/firewall

**Soluciones:**
1. Verificar token en FlutterSecureStorage
2. Confirmar URLs en NetworkConfig
3. Verificar que el servidor esté ejecutándose
4. Probar conectividad HTTP primero

### Problema: Mensajes no se envían
**Causas posibles:**
- WebSocket desconectado
- API REST no responde
- Datos de mensaje inválidos

**Soluciones:**
1. Verificar estado de conexión
2. Revisar logs del servidor
3. Validar datos del mensaje

### Problema: Imágenes no se muestran
**Causas posibles:**
- URL de imagen incorrecta
- Base64 malformado
- Problemas de red

**Soluciones:**
1. Verificar URL de imagen
2. Validar formato Base64
3. Probar con imagen pequeña

## 📚 Mejores Prácticas

### 1. Gestión de Estado
- Usar `StreamController` para datos reactivos
- Verificar `mounted` antes de actualizar UI
- Limpiar suscripciones en `dispose()`

### 2. Manejo de Memoria
- Cancelar timers en `dispose()`
- Limpiar controladores de texto
- Evitar memory leaks en streams

### 3. UX/UI
- Mostrar indicadores de carga
- Feedback visual para acciones del usuario
- Manejo graceful de errores

### 4. Performance
- Lazy loading de mensajes
- Paginación para conversaciones largas
- Optimización de imágenes

### 5. Seguridad
- Validar datos en cliente y servidor
- Sanitizar contenido de mensajes
- Rate limiting para envío de mensajes

## 🚀 Funcionalidades Futuras

- [ ] Mensajes de voz
- [ ] Videollamadas
- [ ] Reacciones a mensajes
- [ ] Mensajes programados
- [ ] Búsqueda en conversaciones
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Cifrado end-to-end

---

## 📞 Soporte

Para dudas o problemas con el sistema de chat, contactar al equipo de desarrollo o revisar los logs de la aplicación.

**Última actualización**: Enero 2024
**Versión**: 1.0.0
