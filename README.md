# 🛒 Marketplace UCT

Una aplicación Flutter completa de marketplace con backend Node.js y PostgreSQL.

## 🚀 Características

- **Frontend**: Flutter multiplataforma (iOS, Android, Web)
- **Backend**: Node.js con Express y Prisma ORM
- **Base de datos**: PostgreSQL
- **Autenticación**: JWT + Google Auth
- **Funcionalidades**: 
  - Sistema de usuarios (Admin, Vendedor, Cliente)
  - CRUD de productos
  - Chat entre usuarios
  - Sistema de calificaciones
  - Panel de administración

## 📱 Frontend (Flutter)

### Instalación
```bash
flutter pub get
flutter run
```

### Estructura
```
lib/
├── main.dart
├── models/          # Modelos de datos
├── screens/         # Pantallas de la app
├── services/        # Servicios (API, Auth)
├── widgets/         # Widgets reutilizables
└── core/           # Configuración y tema
```

## 🚀 Backend (Node.js + PostgreSQL)

### Configuración rápida
```bash
cd server
npm install
npm run db:push      # Aplicar schema
npm run db:seed      # Datos iniciales
npm run dev          # Iniciar servidor
```

### Servicios en la nube recomendados
- **Neon**: https://neon.tech (PostgreSQL serverless)
- **Supabase**: https://supabase.com
- **Railway**: https://railway.app

Ver [BACKEND_README.md](BACKEND_README.md) para más detalles.

## 🔧 Configuración

1. **PostgreSQL**: Configurar DATABASE_URL en `server/.env`
2. **Flutter**: Actualizar endpoint de API en `lib/services/api_client.dart`
3. **Variables de entorno**: Copiar `server/.env.example` a `server/.env`

## 👤 Usuarios por defecto

| Email | Password | Tipo |
|-------|----------|------|
| admin@uct.cl | admin123 | ADMIN |
| vendedor@uct.cl | vendor123 | VENDEDOR |
| cliente@alu.uct.cl | client123 | CLIENTE |

## 📚 Documentación

- [Backend Setup](BACKEND_README.md)
- [Migración a PostgreSQL](server/POSTGRESQL_MIGRATION.md)
- [Configuración Alternativa](CONFIGURACION_ALTERNATIVA.md)
