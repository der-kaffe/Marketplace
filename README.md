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
  - **Gestión de perfil de usuario**
  - **Sistema de favoritos**

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
│   ├── profile_screen.dart      # 👤 Gestión completa de perfil
│   ├── favorites_screen.dart    # ❤️ Lista de productos favoritos
│   └── home_screen.dart         # 🏠 Con funcionalidad de favoritos
├── services/        # Servicios (API, Auth)
├── widgets/         # Widgets reutilizables
│   └── product_card.dart        # 📦 Con botón de favorito
└── core/           # Configuración y tema
```

### Navegación en la App
- **Perfil**: Accesible desde la barra de navegación inferior (ícono de persona)
- **Favoritos**: Accesible desde la barra de navegación inferior (ícono de corazón)
- **Toggle de favoritos**: Disponible en cada tarjeta de producto (ícono de corazón)

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

## 👤 Gestión de Perfil de Usuario

### Funcionalidades del Perfil
- **Información personal**: Edición de datos como apellido, usuario, campus, teléfono y dirección
- **Autenticación**: Soporte para login con Google y JWT
- **Foto de perfil**: Subida y actualización de imagen de perfil
- **Gestión de productos**: Visualización de productos creados por el usuario
- **Estadísticas**: Contadores de favoritos, reseñas y transacciones

### Características Técnicas
- Integración con Google Sign-In para autenticación
- Actualización de datos en tiempo real
- Validación de formularios
- Manejo de estados de carga y error
- Selector de imágenes desde galería o cámara

```dart
// Pantalla principal: lib/screens/profile_screen.dart
// Funcionalidades incluidas:
- Edición de perfil completa
- Visualización de productos del usuario
- Gestión de favoritos
- Historial de transacciones
```

## ❤️ Sistema de Favoritos

### Funcionalidades de Favoritos
- **Agregar/Quitar favoritos**: Toggle de productos favoritos con un toque
- **Lista de favoritos**: Pantalla dedicada para ver todos los productos guardados
- **Persistencia**: Los favoritos se sincronizan con el backend
- **Contadores**: Visualización del número total de favoritos
- **Actualización en tiempo real**: Los cambios se reflejan instantáneamente

### Características Técnicas
- API REST para gestión de favoritos (`/api/favorites`)
- Sincronización automática entre pantallas
- Cache local para mejor rendimiento
- Indicadores visuales (corazón rojo/gris)
- Manejo de estados offline

```dart
// Pantallas relacionadas:
lib/screens/favorites_screen.dart    // Lista completa de favoritos
lib/screens/profile_screen.dart      // Contador de favoritos
lib/screens/home_screen.dart         // Toggle de favoritos en productos

// Componentes:
lib/widgets/product_card.dart        // Botón de favorito en cada producto
```

### API Endpoints de Favoritos
```javascript
GET    /api/favorites        // Obtener favoritos del usuario
POST   /api/favorites        // Agregar producto a favoritos
DELETE /api/favorites/:id    // Remover producto de favoritos
```

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
