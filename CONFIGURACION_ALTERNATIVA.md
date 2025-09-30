# Configuración Alternativa - Modo Demo

Si necesitas probar rápidamente sin configurar PostgreSQL, puedes usar el servidor en modo "demo" con datos en memoria.

## Opción 1: Modo Demo (Para pruebas rápidas)

Servidor con datos en memoria, sin necesidad de base de datos externa.

### Crear servidor demo:

1. Crear archivo `server/demo-server.js`:

```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:*', 'http://127.0.0.1:*'].map(o => new RegExp(o.replace('*', '\\d+'))),
  credentials: true
}));
app.use(express.json());

// Datos en memoria (simulando base de datos)
const users = [
  {
    id: 1,
    email: 'demo@uct.cl',
    password: '$2a$10$8ZJQJRGOp5GE9q.PLUYQUeIwJvMxXqYdR7lJpOHYzW3z2IzZxrqfu', // demo123
    name: 'Usuario Demo',
    role: 'student'
  },
  {
    id: 2,
    email: 'admin@uct.cl',
    password: '$2a$10$8ZJQJRGOp5GE9q.PLUYQUeIwJvMxXqYdR7lJpOHYzW3z2IzZxrqfu', // demo123
    name: 'Administrador',
    role: 'admin'
  }
];

const products = [
  {
    id: 1,
    user_id: 1,
    title: 'Calculadora Científica Casio',
    description: 'Calculadora científica en excelente estado',
    price: 25000.00,
    category: 'academic',
    condition_type: 'used',
    is_available: true,
    seller_name: 'Usuario Demo',
    seller_email: 'demo@uct.cl',
    created_at: new Date().toISOString()
  }
];

// Rutas
app.get('/api/health', (req, res) => {
  res.json({
    ok: true,
    timestamp: new Date().toISOString(),
    database: 'memory',
    service: 'Marketplace API Demo',
    version: '1.0.0'
  });
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = users.find(u => u.email === email);
    
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales inválidas'
      });
    }
    
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'demo_secret',
      { expiresIn: '7d' }
    );
    
    res.json({
      ok: true,
      message: 'Login exitoso',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ ok: false, message: 'Error interno' });
  }
});

app.get('/api/products', (req, res) => {
  res.json({
    ok: true,
    products,
    pagination: { page: 1, limit: 20, total: products.length }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor DEMO corriendo en http://localhost:${PORT}`);
  console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
  console.log(`👤 Usuarios demo: demo@uct.cl / demo123`);
  console.log(`📝 Modo: DEMO (datos en memoria)`);
});
```

### Ejecutar servidor demo:

```bash
cd server
node demo-server.js
```

## Opción 2: Configuración con PostgreSQL + Prisma

Si prefieres usar PostgreSQL (recomendado):

1. **Instalar PostgreSQL:**
   - Descargar desde: https://www.postgresql.org/download/
   - O usar Docker: `docker run --name postgres -e POSTGRES_PASSWORD=password -d -p 5432:5432 postgres`

2. **Configurar variables de entorno:**
   ```bash
   cd server
   # Editar .env con tu configuración
   ```

3. **Configurar base de datos:**
   ```bash
   npm install
   npm run db:push
   npm run db:seed
   npm run dev
   ```

4. **Usuarios por defecto creados:**
   - admin@uct.cl / admin123 (ADMIN)
   - vendedor@uct.cl / vendor123 (VENDEDOR)
   - cliente@alu.uct.cl / client123 (CLIENTE)
DB_PASSWORD=tu_password_mysql
```

## Próximos Pasos

Una vez que tengas el servidor funcionando (demo o MySQL), podrás:

1. **Probar la API** en http://localhost:3001/api/health
2. **Usar tu app Flutter** con login de email/password
3. **Añadir más productos y usuarios**

¿Cuál opción prefieres usar?
