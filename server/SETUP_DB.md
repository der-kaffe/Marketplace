# 🚀 Configuración Manual de Base de Datos

Ya que tienes MySQL corriendo, vamos a configurar la base de datos manualmente.

## Opción 1: MySQL Workbench (Recomendado)

1. **Abrir MySQL Workbench**
2. **Conectar a tu servidor local**
   - Host: `localhost`
   - Port: `3306`
   - Usuario: `root` (probablemente)
   - Password: (prueba vacío primero)

3. **Ejecutar el script SQL**
   - Abrir el archivo: `server/sql/setup-manual.sql`
   - Ejecutar todo el script (Ctrl+Shift+Enter)

## Opción 2: Línea de Comandos

Si tienes el comando `mysql` disponible:

```bash
mysql -u root -p < server/sql/setup-manual.sql
```

## Opción 3: phpMyAdmin (si usas XAMPP)

1. Ir a http://localhost/phpmyadmin
2. Crear base de datos `marketplace`
3. Importar el archivo `server/sql/setup-manual.sql`

## Verificar Credenciales

Después de configurar la base de datos, verifica las credenciales en `server/.env`:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root          # Tu usuario de MySQL
DB_PASSWORD=          # Tu password de MySQL (puede estar vacío)
DB_NAME=marketplace
```

## Usuarios de Prueba Creados

- **demo@uct.cl** / **demo123** (estudiante)
- **admin@uct.cl** / **demo123** (administrador)

## Siguiente Paso

Una vez configurada la base de datos, ejecuta:

```bash
npm run dev
```

El servidor debería iniciarse en http://localhost:3001

## ¿Problemas de Conexión?

Si tienes problemas, intenta estas configuraciones comunes:

### XAMPP:
```env
DB_USER=root
DB_PASSWORD=
```

### MySQL Workbench:
```env
DB_USER=root
DB_PASSWORD=tu_password
```

### MySQL con autenticación:
```env
DB_USER=tu_usuario
DB_PASSWORD=tu_password
```
