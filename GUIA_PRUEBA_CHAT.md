# 🧪 Guía para Probar el Chat en Tiempo Real

## 📋 Preparación

### 1. Instalar Dependencias
```bash
# Servidor
cd server
npm install

# Flutter
flutter pub get
```

### 2. Configurar Base de Datos
```bash
cd server
npm run db:push
npm run db:seed
```

### 3. Iniciar Servidor
```bash
cd server
npm run dev
```

## 🎯 Datos de Prueba Disponibles

### Usuarios Creados
- **Admin**: `admin@uct.cl` / `admin123`
- **Vendedor**: `vendedor@uct.cl` / `vendor123`  
- **Cliente**: `cliente@alu.uct.cl` / `client123`

### Conversaciones de Prueba
- **Vendedor ↔ Cliente**: Conversación sobre laptop Dell
- **Admin ↔ Cliente**: Conversación de soporte

## 🧪 Probar Endpoints REST

### Opción 1: Script Automático
```bash
cd server
node ../test_chat_endpoints.js
```

### Opción 2: Pruebas Manuales con Postman/Thunder Client

#### 1. Login de Usuario
```http
POST http://localhost:3001/api/auth/login
Content-Type: application/json

{
  "email": "cliente@alu.uct.cl",
  "password": "client123"
}
```

#### 2. Obtener Conversaciones
```http
GET http://localhost:3001/api/chat/conversaciones
Authorization: Bearer {token_del_login}
```

#### 3. Obtener Mensajes de Conversación
```http
GET http://localhost:3001/api/chat/conversacion/{usuarioId}
Authorization: Bearer {token_del_login}
```

#### 4. Enviar Mensaje
```http
POST http://localhost:3001/api/chat/send
Authorization: Bearer {token_del_login}
Content-Type: application/json

{
  "destinatarioId": 2,
  "contenido": "Hola! ¿Cómo estás?"
}
```

## 📱 Probar Chat en Flutter

### 1. Ejecutar Aplicación
```bash
flutter run
```

### 2. Login con Usuario de Prueba
- Usar cualquiera de los usuarios de prueba
- El chat se inicializará automáticamente

### 3. Navegar al Chat
- Ir a la sección de "Chats" en la app
- Verás las conversaciones existentes
- Toca una conversación para abrir el chat

### 4. Probar Funcionalidades
- ✅ **Envío de mensajes**: Escribe y envía mensajes
- ✅ **Tiempo real**: Abre la app en dos dispositivos/emuladores
- ✅ **Indicadores de escritura**: Escribe para ver "está escribiendo..."
- ✅ **Persistencia**: Los mensajes se guardan en la base de datos

## 🔄 Probar Chat en Tiempo Real

### Método 1: Dos Emuladores
1. Ejecutar `flutter run` en dos terminales diferentes
2. Login con usuarios diferentes en cada emulador
3. Iniciar conversación entre ellos
4. Ver mensajes en tiempo real

### Método 2: Emulador + Postman
1. Login en la app Flutter con un usuario
2. Usar Postman para enviar mensajes como otro usuario
3. Ver mensajes aparecer en tiempo real en la app

### Método 3: WebSocket Directo
```javascript
// En consola del navegador
const socket = io('http://localhost:3001', {
  auth: { token: 'tu_jwt_token_aqui' }
});

socket.on('connect', () => console.log('Conectado!'));
socket.on('new_message', (msg) => console.log('Nuevo mensaje:', msg));

// Enviar mensaje
socket.emit('send_message', {
  destinatarioId: 2,
  contenido: 'Hola desde WebSocket!'
});
```

## 🐛 Solución de Problemas

### WebSocket no conecta
- Verificar que el servidor esté corriendo en puerto 3001
- Verificar token JWT válido
- Revisar logs del servidor

### Mensajes no aparecen
- Verificar que ambos usuarios estén autenticados
- Verificar que el destinatarioId sea correcto
- Revisar logs de la base de datos

### Indicadores de escritura no funcionan
- Verificar conexión WebSocket
- Verificar que el evento `typing_start` se envíe

## 📊 Verificar en Base de Datos

```sql
-- Ver todos los mensajes
SELECT m.*, r.nombre as remitente, d.nombre as destinatario 
FROM mensajes m
JOIN cuentas r ON m.remitente_id = r.id
JOIN cuentas d ON m.destinatario_id = d.id
ORDER BY m.fecha_envio DESC;

-- Ver conversaciones de un usuario
SELECT DISTINCT 
  CASE 
    WHEN m.remitente_id = 1 THEN d.nombre 
    ELSE r.nombre 
  END as otro_usuario,
  m.contenido as ultimo_mensaje,
  m.fecha_envio
FROM mensajes m
JOIN cuentas r ON m.remitente_id = r.id
JOIN cuentas d ON m.destinatario_id = d.id
WHERE m.remitente_id = 1 OR m.destinatario_id = 1
ORDER BY m.fecha_envio DESC;
```

## 🎉 ¡Listo!

Con estos pasos podrás probar completamente el sistema de chat en tiempo real. Los mensajes se sincronizan automáticamente entre usuarios y se persisten en la base de datos.

