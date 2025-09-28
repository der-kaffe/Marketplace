# Configuración Alternativa - Sin Base de Datos

Si tienes problemas configurando MySQL, puedes usar el servidor en modo "demo" sin base de datos.

## Opción 1: Modo Demo (Recomendado para pruebas)

Vamos a configurar el servidor para que funcione con datos en memoria sin necesidad de MySQL.

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

## Opción 2: Configuración Manual de MySQL

Si prefieres usar MySQL:

1. **Abre MySQL Workbench o MySQL Command Line**
2. **Conecta con tus credenciales actuales**
3. **Ejecuta este script SQL:**

```sql
CREATE DATABASE IF NOT EXISTS marketplace;
USE marketplace;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('student', 'admin', 'guest') DEFAULT 'student',
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (email, password, name, role, email_verified) VALUES 
('demo@uct.cl', '$2a$10$8ZJQJRGOp5GE9q.PLUYQUeIwJvMxXqYdR7lJpOHYzW3z2IzZxrqfu', 'Usuario Demo', 'student', TRUE);
```

4. **Actualiza el archivo `server/.env` con tus credenciales:**

```env
DB_USER=tu_usuario_mysql
DB_PASSWORD=tu_password_mysql
```

## Próximos Pasos

Una vez que tengas el servidor funcionando (demo o MySQL), podrás:

1. **Probar la API** en http://localhost:3001/api/health
2. **Usar tu app Flutter** con login de email/password
3. **Añadir más productos y usuarios**

¿Cuál opción prefieres usar?
