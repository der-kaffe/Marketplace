const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

// Crear instancia de Prisma
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
  errorFormat: 'pretty',
});

// Función para probar la conexión
async function testConnection() {
  try {
    await prisma.$connect();
    console.log('✅ Conexión a PostgreSQL establecida correctamente');
    return true;
  } catch (error) {
    console.error('❌ Error conectando a PostgreSQL:', error.message);
    return false;
  }
}

// Función para cerrar la conexión
async function closeConnection() {
  try {
    await prisma.$disconnect();
    console.log('✅ Conexión a PostgreSQL cerrada correctamente');
  } catch (error) {
    console.error('❌ Error cerrando conexión a PostgreSQL:', error.message);
  }
}

// Manejo de cierre graceful
process.on('SIGINT', async () => {
  await closeConnection();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await closeConnection();
  process.exit(0);
});

module.exports = { 
  prisma, 
  testConnection, 
  closeConnection 
};
