# Marketplace UCT - Backend Setup

Este proyecto incluye un backend Node.js con MySQL para la aplicación Flutter Marketplace.

## 🚀 Configuración Rápida

### Prerrequisitos
- Node.js 18+ instalado
- MySQL 8.0+ instalado (XAMPP, MySQL Workbench, o instalación directa)

### Opción 1: Con Docker (Recomendado)
```bash
docker-compose up -d
cd server
npm install
npm run dev
```

### Opción 2: Sin Docker (MySQL local)

1. **Instalar MySQL:**
   - Descargar e instalar MySQL desde: https://dev.mysql.com/downloads/mysql/
   - O usar XAMPP: https://www.apachefriends.org/download.html

2. **Configurar Base de Datos:**
   ```sql
   CREATE DATABASE marketplace;
   CREATE USER 'marketuser'@'localhost' IDENTIFIED BY 'market123';
   GRANT ALL PRIVILEGES ON marketplace.* TO 'marketuser'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Ejecutar script SQL:**
   - Importar el archivo `server/sql/init.sql` en MySQL Workbench o phpMyAdmin

4. **Iniciar el servidor:**
   - Hacer doble clic en `start-server.bat`
   - O manualmente:
     ```bash
     cd server
     npm install
     npm run dev
     ```

## 📁 Estructura del Backend

```
server/
├── config/
│   └── database.js          # Configuración MySQL
├── middleware/
│   └── auth.js              # Middleware de autenticación JWT
├── routes/
│   ├── auth.js              # Rutas de autenticación
│   ├── users.js             # Rutas de usuarios
│   └── products.js          # Rutas de productos
├── sql/
│   └── init.sql             # Script de inicialización DB
├── .env                     # Variables de entorno
├── package.json
└── server.js               # Servidor principal
```

## 🔧 Configuración

### Variables de Entorno (.env)
```env
PORT=3001
DB_HOST=localhost
DB_PORT=3306
DB_USER=marketuser
DB_PASSWORD=market123
DB_NAME=marketplace
JWT_SECRET=tu_jwt_secret_muy_seguro_aqui_2024_marketplace
CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*
NODE_ENV=development
```

## 📊 Endpoints de la API

### Autenticación
- `POST /api/auth/login` - Login con email/password
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/google` - Login con Google

### Usuarios
- `GET /api/users/profile` - Perfil del usuario actual
- `GET /api/users` - Listar usuarios (admin)

### Productos
- `GET /api/products` - Listar productos
- `GET /api/products/:id` - Obtener producto
- `POST /api/products` - Crear producto
- `GET /api/products/categories/list` - Listar categorías

### Health Check
- `GET /api/health` - Estado del servidor y DB

## 🧪 Usuarios de Prueba

| Email | Password | Rol |
|-------|----------|-----|
| demo@uct.cl | demo123 | student |
| admin@uct.cl | demo123 | admin |

## 🛠️ Testing de la API

### Con curl:
```bash
# Health check
curl http://localhost:3001/api/health

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@uct.cl","password":"demo123"}'

# Listar productos
curl http://localhost:3001/api/products
```

### Con Postman:
Importar la colección desde: `server/postman/marketplace-api.postman_collection.json` (próximamente)

## 🔍 Panel de Administración MySQL

Si usas Docker:
- Adminer: http://localhost:8080
- Servidor: `mysql`
- Usuario: `marketuser`
- Password: `market123`
- Base de datos: `marketplace`

## ⚡ Flutter Integration

El cliente API ya está configurado en `lib/services/api_client.dart`:

```dart
// Ejemplo de uso
final authService = AuthService();
final response = await authService.loginWithEmail(email, password);

if (response.ok) {
  // Login exitoso
  context.go('/home');
}
```

## 🐛 Troubleshooting

### Error de conexión a MySQL
1. Verificar que MySQL esté corriendo
2. Comprobar credenciales en `.env`
3. Verificar que la base de datos `marketplace` existe

### Error CORS en Flutter Web
- Verificar que `CORS_ORIGIN` incluye `http://localhost:*`

### Error JWT
- Verificar que `JWT_SECRET` esté configurado
- Comprobar que el token se envía en el header `Authorization: Bearer <token>`

## 📝 TODO

- [ ] Implementar refresh tokens
- [ ] Añadir validación de imágenes
- [ ] Implementar notificaciones push
- [ ] Añadir rate limiting por usuario
- [ ] Implementar soft delete para productos
- [ ] Añadir logging con Winston

## 🤝 Contribuir

1. Fork el proyecto
2. Crear una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Añadir nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request
