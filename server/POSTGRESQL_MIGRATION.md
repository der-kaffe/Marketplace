# Migración a PostgreSQL con Prisma

Este proyecto ha sido migrado de MySQL a PostgreSQL utilizando Prisma ORM como capa de abstracción de base de datos.

## 🚀 Configuración Rápida

### 1. Instalar Dependencias

```bash
cd server
npm install
```

### 2. Configurar PostgreSQL

Asegúrate de tener PostgreSQL instalado y corriendo. Puedes usar:

- **PostgreSQL local**: Instala PostgreSQL en tu máquina
- **Docker**: `docker run --name postgres -e POSTGRES_PASSWORD=password -d -p 5432:5432 postgres`
- **Servicios en la nube**: Neon, Supabase, Railway, etc.

### 3. Configurar Variables de Entorno

Copia el archivo de ejemplo y configúralo:

```bash
cp .env.example .env
```

Edita `.env` con tu configuración:

```env
DATABASE_URL="postgresql://username:password@localhost:5432/marketplace?schema=public"
JWT_SECRET=tu_jwt_secret_muy_seguro
NODE_ENV=development
PORT=3001
```

### 4. Ejecutar Migraciones

```bash
# Generar el cliente de Prisma
npm run db:generate

# Aplicar el schema a la base de datos
npm run db:push

# O usar migraciones (recomendado para producción)
npm run db:migrate
```

### 5. Poblar la Base de Datos (Opcional)

```bash
npm run db:seed
```

### 6. Iniciar el Servidor

```bash
npm run dev
```

## 🛠️ Scripts Disponibles

```bash
npm run start          # Iniciar servidor en producción
npm run dev            # Iniciar servidor en desarrollo
npm run db:generate    # Generar cliente de Prisma
npm run db:push        # Aplicar schema sin migraciones
npm run db:migrate     # Crear y aplicar migraciones
npm run db:seed        # Poblar base de datos con datos iniciales
npm run db:studio      # Abrir Prisma Studio (GUI para base de datos)
```

## 📊 Prisma Studio

Para explorar y editar los datos visualmente:

```bash
npm run db:studio
```

Esto abrirá una interfaz web en `http://localhost:5555`

## 🔄 Cambios Principales en la Migración

### Dependencias
- ❌ Removido: `mysql2`
- ✅ Agregado: `@prisma/client`, `prisma`

### Configuración de Base de Datos
- **Antes**: `config/database.js` con pool de conexiones MySQL
- **Ahora**: `config/database.js` con Prisma Client

### Consultas
- **Antes**: SQL queries directas con `pool.query()`
- **Ahora**: Prisma ORM con métodos como `prisma.cuentas.findMany()`

### Nomenclatura
- Tablas y campos ahora siguen convenciones de Prisma
- Enums definidos en el schema para mejor type safety

## 🏗️ Estructura del Schema

### Modelos Principales
- `Cuentas` - Usuarios del sistema
- `Productos` - Productos en venta
- `Transacciones` - Compras y ventas
- `Calificaciones` - Sistema de reseñas
- `Mensajes` - Chat entre usuarios
- `Carrito` - Carrito de compras

### Enums
- `TipoUsuario`: ADMIN, VENDEDOR, CLIENTE, MODERADOR
- `EstadoTransaccion`: PENDIENTE, CONFIRMADA, ENVIADA, ENTREGADA, CANCELADA, REEMBOLSADA

## 🔒 Usuarios por Defecto (después del seed)

| Email | Password | Tipo |
|-------|----------|------|
| admin@uct.cl | admin123 | ADMIN |
| vendedor@uct.cl | vendor123 | VENDEDOR |
| cliente@alu.uct.cl | client123 | CLIENTE |

## 🌐 Servicios de PostgreSQL Recomendados

### Para Desarrollo
- **Local**: PostgreSQL instalado localmente
- **Docker**: Fácil setup con contenedores

### Para Producción
- **Neon**: https://neon.tech (Serverless PostgreSQL)
- **Supabase**: https://supabase.com (PostgreSQL + APIs)
- **Railway**: https://railway.app (Deploy fácil)
- **Render**: https://render.com (PostgreSQL gratuito)

## 📝 Notas Importantes

1. **Conexiones**: Prisma maneja automáticamente el pool de conexiones
2. **Migrations**: Usa `db:migrate` en producción para cambios de schema
3. **Type Safety**: Prisma genera tipos TypeScript automáticamente
4. **Performance**: Prisma incluye query optimization por defecto
5. **Monitoring**: Habilita logs en desarrollo para debug

## 🚨 Troubleshooting

### Error de conexión
```bash
Error: P1001: Can't reach database server
```
- Verifica que PostgreSQL esté corriendo
- Revisa la `DATABASE_URL` en `.env`
- Confirma usuario, password y puerto

### Error de schema
```bash
Error: P3009: Introspection failed
```
- Ejecuta `npm run db:push` para sincronizar el schema
- O `npm run db:migrate` si usas migraciones

### Performance lenta
- Revisa los índices en `schema.prisma`
- Usa `prisma.queryRaw()` para queries complejas
- Habilita query logging para debug

## 📖 Documentación Adicional

- [Prisma Documentation](https://www.prisma.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Prisma Best Practices](https://www.prisma.io/docs/guides/performance-and-optimization)
