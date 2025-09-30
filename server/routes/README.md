
````markdown
# 📌 API de Autenticación

Este módulo maneja todo lo relacionado con **autenticación y registro de usuarios**.  
Incluye login con credenciales, login con Google, registro de usuarios y consulta de perfil con JWT.

---

## 🔑 Rutas disponibles

### 1. **POST /api/auth/login**

Inicia sesión con correo y contraseña.

**Body (JSON):**

```json
{
  "email": "admin@uct.cl",
  "password": "admin123"
}
```
````

**Response (200 OK):**

```json
{
  "ok": true,
  "message": "Login exitoso",
  "token": "JWT_TOKEN",
  "user": {
    "id": 1,
    "email": "admin@uct.cl",
    "nombre": "Administrador",
    "apellido": "Sistema",
    "role": "Administrador",
    "campus": "Campus Temuco",
    "reputacion": "5"
  }
}
```

---

### 2. **POST /api/auth/register**

Registra un nuevo usuario con validaciones:

- Solo correos `@uct.cl` y `@alu.uct.cl`.
- Contraseña mínima de 6 caracteres.
- Usuario único.

**Body (JSON):**

```json
{
  "email": "alumno@alu.uct.cl",
  "password": "123456",
  "nombre": "Juan",
  "usuario": "juanc"
}
```

**Response (201 Created):**

```json
{
  "ok": true,
  "message": "Usuario registrado exitosamente",
  "token": "JWT_TOKEN",
  "user": {
    "id": 2,
    "correo": "alumno@alu.uct.cl",
    "usuario": "juanc",
    "nombre": "Juan",
    "apellido": "",
    "role": "Alumno",
    "campus": "Campus Temuco"
  }
}
```

---

### 3. **POST /api/auth/google**

Permite autenticación con Google (se espera `idToken`, email y nombre).

**Body (JSON):**

```json
{
  "idToken": "GOOGLE_ID_TOKEN",
  "email": "admin@uct.cl",
  "name": "Administrador"
}
```

**Response (200 OK):**

```json
{
  "ok": true,
  "message": "Login con Google exitoso",
  "token": "JWT_TOKEN",
  "user": {
    "id": 1,
    "correo": "admin@uct.cl",
    "usuario": "admin_1696012345678",
    "nombre": "Administrador",
    "role": "Administrador",
    "campus": "Campus Temuco"
  }
}
```

---

### 4. **GET /api/auth/me**

Devuelve el perfil del usuario autenticado (requiere `Authorization: Bearer TOKEN`).
Permite elegir **qué información incluir** con el parámetro `include`.

#### Modos de uso:

- `/me` → trae todo.
- `/me?include=perfil` → solo datos básicos (rol y estado).
- `/me?include=notificaciones` → solo notificaciones + lo básico.
- `/me?include=productos,seguidores` → datos específicos.
- `/me?include=todo` → explícitamente todo.

**Ejemplo Request:**

```
GET /api/auth/me
Authorization: Bearer JWT_TOKEN
```

**Ejemplo Response (todo):**

```json
{
  "ok": true,
  "user": {
    "id": 1,
    "correo": "admin@uct.cl",
    "nombre": "Administrador",
    "rol": { "id": 1, "nombre": "Administrador" },
    "estado": { "id": 1, "nombre": "Activo" },
    "productos": [...],
    "transaccionesCompra": [...],
    "transaccionesVenta": [...],
    "calificacionesRecibidas": [...],
    "notificaciones": [...],
    "seguidores": [...],
    "siguiendo": [...],
    "resumenUsuario": {...},
    ...
  }
}
```

---

## ⚙️ Variables de entorno requeridas

En el archivo `.env` deben estar configuradas:

```
JWT_SECRET=tu_clave_secreta
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
```

---

## 📚 Notas

- Todos los endpoints devuelven objetos JSON con la clave `ok` para indicar éxito o error.
- Si ocurre un error de validación, se devuelve `400` con detalles de los campos inválidos.
- Si el token no es válido o falta, se devuelve `401` o `403`.

---

```

```
