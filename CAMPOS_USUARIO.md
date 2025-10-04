# 📝 Campos de Usuario: Solo Lectura vs Editables

## 🔒 **Campos de Solo Lectura (Vienen de Google OAuth)**

Estos campos se obtienen directamente de Google y **NO** se pueden editar en la aplicación:

| Campo | Fuente | Descripción |
|-------|--------|-------------|
| `correo` | Google OAuth | Email de la cuenta @uct.cl o @alu.uct.cl |
| `nombre` | Google OAuth | Nombre completo desde Google |
| `role` | Sistema | Asignado automáticamente según dominio de email |
| `id` | Sistema | ID único generado por la base de datos |

## ✏️ **Campos Editables por el Usuario**

Estos campos pueden ser modificados por el usuario en la aplicación:

| Campo | Valor Inicial | Descripción |
|-------|---------------|-------------|
| `apellido` | `""` (vacío) | Apellido adicional (opcional) |
| `usuario` | Generado automáticamente | Nombre de usuario único |
| `campus` | `"Campus Temuco"` | Campus o ubicación del usuario |
| `telefono` | `null` | Número de teléfono (se añadirá después) |
| `direccion` | `null` | Dirección física (se añadirá después) |

## 🏗️ **Proceso de Creación de Usuario**

### **Primera vez (Usuario nuevo):**
```javascript
// Valores iniciales automáticos
{
  correo: "usuario@uct.cl",           // ← De Google
  nombre: "Juan Pérez",               // ← De Google  
  apellido: "",                       // ← Editable (vacío inicialmente)
  usuario: "juan_perez_1696234567",   // ← Generado automáticamente
  campus: "Campus Temuco",            // ← Valor por defecto
  rolId: 2,                          // ← Según dominio (@uct.cl vs @alu.uct.cl)
  estadoId: 1,                       // ← Activo por defecto
}
```

### **Próximos logins:**
- Los campos de Google se mantienen actualizados
- Los campos editables conservan los valores que el usuario haya cambiado

## 🎯 **Flujo de Edición en Flutter**

### **Pantalla de Perfil:**
```dart
// Campos mostrados como solo lectura
Text('Email: ${user.correo}');        // 🔒 No editable
Text('Nombre: ${user.nombre}');       // 🔒 No editable

// Campos editables con botón de editar
_buildEditableField('Apellido', user.apellido);     // ✏️ Editable  
_buildEditableField('Usuario', user.usuario);       // ✏️ Editable
_buildEditableField('Campus', user.campus);         // ✏️ Editable
```

## 🔄 **API para Actualizar Campos Editables**

```javascript
// Endpoint para actualizar campos editables
PUT /api/users/profile
{
  "apellido": "García",
  "usuario": "juan_garcia",
  "campus": "Campus Norte",
  "telefono": "+56 9 1234 5678",
  "direccion": "Av. Alemania 0211"
}
```

## 📊 **Respuesta del Login con Clasificación**

```json
{
  "ok": true,
  "message": "¡Cuenta creada/actualizada en base de datos!",
  "token": "jwt_token_here",
  "user": {
    "id": 123,
    "correo": "usuario@uct.cl",      // 🔒 Solo lectura
    "nombre": "Juan Pérez",          // 🔒 Solo lectura  
    "apellido": "",                  // ✏️ Editable
    "usuario": "juan_perez_123",     // ✏️ Editable
    "campus": "Campus Temuco",       // ✏️ Editable
    "role": "vendedor",              // 🔒 Solo lectura
    "editableFields": ["apellido", "usuario", "campus", "telefono", "direccion"]
  }
}
```

¡Ahora está claro qué campos vienen de Google (solo lectura) y cuáles puede editar el usuario! 🎉
