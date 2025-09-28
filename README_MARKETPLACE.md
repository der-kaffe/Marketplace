# Marketplace UCT - Guía Rápida

## 🎯 Estado del Proyecto

✅ **COMPLETADO:**
- Base de datos `marketplace.sql` importada
- Backend Node.js configurado
- Flutter actualizado para el backend
- Script de población de datos: `populate-database.js`

## 🚀 Inicio Rápido

### 1. Poblar Base de Datos (solo primera vez)

```bash
# Opción 1: Script automático
setup-database.bat

# Opción 2: Manual
cd server
node scripts/populate-database.js
```

### 2. Iniciar Servidor Backend

```bash
cd server
node server.js
```

### 3. Ejecutar Flutter

```bash
flutter run
```

## 🗄️ Base de Datos Configurada

### Tablas Principales:
- **cuentas** - Usuarios del sistema
- **productos** - Productos del marketplace
- **categorias** - Categorías de productos
- **transacciones** - Historial de compras/ventas
- **mensajes** - Sistema de chat
- **calificaciones** - Reseñas y ratings
- **reportes** - Sistema de reportes
- Y 17 tablas más...

### Usuario de Prueba:
- **Email:** `test@uct.cl`
- **Password:** `123456`
- **Rol:** Usuario
- **Campus:** Temuco

## 🔧 API Endpoints Disponibles

### Autenticación:
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/register` - Registrar usuario  
- `GET /api/auth/profile` - Obtener perfil

### Sistema:
- `GET /api/health` - Estado del servidor

## 📱 Probar la Conexión

### En Flutter:
1. Ejecuta la app
2. Ve a la pantalla de login
3. Usa las credenciales de prueba: `test@uct.cl` / `123456`

### Con navegador:
- Health check: http://localhost:3001/api/health

### Con Postman/curl:
```bash
# Health check
curl http://localhost:3001/api/health

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@uct.cl","password":"123456"}'
```

## 🔍 Estructura de Respuesta del Backend

### Login exitoso:
```json
{
  "ok": true,
  "message": "Login exitoso",
  "data": {
    "user": {
      "id": 2,
      "name": "Test Usuario",
      "email": "test@uct.cl",
      "username": "testuser",
      "role": "Usuario",
      "campus": "Temuco",
      "reputation": 0
    },
    "accessToken": "jwt_token_here...",
    "refreshToken": "refresh_token_here..."
  }
}
```

## 🛠️ Configuración de Desarrollo

### Variables de Entorno (.env):
```env
PORT=3001
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=12345678
DB_NAME=marketplace
JWT_SECRET=tu_jwt_secret_muy_seguro_aqui_2024_marketplace
CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*
NODE_ENV=development
```

### URL del API en Flutter:
- **Web:** `http://localhost:3001`
- **Android Emulador:** `http://10.0.2.2:3001`
- **Dispositivo físico:** `http://[TU_IP]:3001`

## 📂 Archivos Importantes

### Backend:
- `server/server.js` - Servidor principal
- `server/routes/auth-marketplace.js` - Rutas de autenticación adaptadas
- `server/sql/marketplace.sql` - Tu base de datos original
- `server/.env` - Configuración

### Flutter:
- `lib/services/auth_service.dart` - Servicio de autenticación
- `lib/services/api_client.dart` - Cliente HTTP actualizado
- `lib/core/config/api_config.dart` - Configuración de API
- `lib/screens/login_screen.dart` - Pantalla de login actualizada

## 🚨 Solución de Problemas

### Error de conexión a MySQL:
1. Verifica que MySQL esté corriendo: `Get-Service | Where-Object {$_.Name -like "*mysql*"}`
2. Confirma las credenciales en `.env`
3. Ejecuta: `node scripts/test-mysql-connection.js`

### Error "usuario no encontrado":
1. Verifica que el usuario de prueba existe: `node scripts/create-test-user.js`
2. Confirma que las tablas básicas estén pobladas: `node scripts/populate-basic-data.js`

### Flutter no puede conectar:
1. Verifica la URL en `api_config.dart`
2. Para emulador Android, usa `http://10.0.2.2:3001`
3. Para dispositivo físico, usa la IP de tu computadora

## 🎉 Próximos Pasos

1. **Probar el login** con las credenciales de prueba
2. **Crear productos** usando las categorías existentes
3. **Implementar chat** usando la tabla `mensajes`
4. **Sistema de calificaciones** con la tabla `calificaciones`
5. **Reportes administrativos** con la tabla `reportes`

## 📞 Soporte

Si encuentras algún problema:
1. Revisa los logs del servidor
2. Verifica la consola de Flutter
3. Ejecuta `test-backend.bat` para diagnósticos automáticos

---

**¡Tu marketplace está listo para usar con tu base de datos personalizada! 🚀**
