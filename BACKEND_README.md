# Marketplace UCT - Backend Setup

Este proyecto incluye un backend Node.js con PostgreSQL y Prisma ORM para la aplicación Flutter Marketplace.

## 🚀 Configuración Rápida

### Prerrequisitos
- Node.js 18+ instalado
- PostgreSQL 12+ instalado

### Opción 1: Con Docker (Recomendado)
```bash
# Iniciar PostgreSQL con Docker
docker run --name postgres -e POSTGRES_PASSWORD=password -d -p 5432:5432 postgres

cd server
npm install
npm run db:push
npm run db:seed
npm run dev
```

### Opción 2: PostgreSQL local

1. **Instalar PostgreSQL:**
   - Descargar desde: https://www.postgresql.org/download/
   - O usar Docker como se muestra arriba

2. **Configurar variables de entorno:**
   - Editar `server/.env` con tu configuración:
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/marketplace"
   ```

3. **Configurar base de datos:**
   ```bash
   cd server
   npm install
   npm run db:push     # Aplicar schema
   npm run db:seed     # Datos iniciales
   npm run dev         # Iniciar servidor
   ```

### Opción 3: Servicios en la nube
- **Neon**: https://neon.tech (PostgreSQL serverless)
- **Supabase**: https://supabase.com
- **Railway**: https://railway.app

## 📁 Estructura del Backend

```
server/
├── config/
│   └── database.js          # Configuración Prisma
├── middleware/
│   └── auth.js              # Middleware de autenticación JWT
├── prisma/
│   ├── schema.prisma        # Schema de base de datos
│   └── seed.js              # Datos iniciales
├── routes/
│   ├── auth.js              # Rutas de autenticación
│   ├── users.js             # Rutas de usuarios
│   └── products.js          # Rutas de productos
├── .env                     # Variables de entorno
├── package.json
└── server.js               # Servidor principal
```

## 🔧 Configuración

### Variables de Entorno (.env)
```env
DATABASE_URL="postgresql://username:password@localhost:5432/marketplace"
PORT=3001
JWT_SECRET=marketplace_jwt_secret_super_seguro_cambiar_en_produccion_2024
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
NODE_ENV=development
BCRYPT_ROUNDS=12
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

## 🧪 Usuarios de Prueba (después del seed)

| Email | Password | Rol |
|-------|----------|-----|
| admin@uct.cl | admin123 | ADMIN |
| vendedor@uct.cl | vendor123 | VENDEDOR |
| cliente@alu.uct.cl | client123 | CLIENTE |

## 🛠️ Scripts Disponibles

```bash
npm run dev          # Iniciar servidor en desarrollo
npm run start        # Iniciar servidor en producción
npm run db:generate  # Generar cliente Prisma
npm run db:push      # Aplicar schema sin migraciones
npm run db:migrate   # Crear y aplicar migraciones
npm run db:seed      # Poblar con datos iniciales
npm run db:studio    # Abrir Prisma Studio
npm run verify       # Verificar configuración
```

## 🧪 Testing de la API

### Con curl:
```bash
# Health check
curl http://localhost:3001/api/health

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@uct.cl","password":"admin123"}'

# Listar productos
curl http://localhost:3001/api/products
```

## 🔍 Panel de Administración de Base de Datos

### Prisma Studio (Recomendado)
```bash
npm run db:studio
```
- URL: http://localhost:5555
- Interfaz visual para explorar y editar datos

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
