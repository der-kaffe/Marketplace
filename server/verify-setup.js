const { prisma, testConnection } = require('./config/database');

async function verifySetup() {
  console.log('🔍 Verificando configuración de PostgreSQL + Prisma...\n');

  try {
    // Test 1: Conexión a la base de datos
    console.log('1. Probando conexión a PostgreSQL...');
    const connected = await testConnection();
    if (!connected) {
      console.log('❌ No se pudo conectar a PostgreSQL');
      console.log('💡 Verifica tu DATABASE_URL en el archivo .env');
      return false;
    }

    // Test 2: Verificar que las tablas existen
    console.log('2. Verificando estructura de base de datos...');
    try {
      const tablesCount = await prisma.$queryRaw`
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
      `;
      console.log(`✅ Base de datos configurada con ${tablesCount[0].count} tablas`);
    } catch (error) {
      console.log('⚠️  Base de datos sin inicializar - ejecuta: npm run db:push');
    }

    // Test 3: Probar consulta básica
    console.log('3. Probando consultas básicas...');
    try {
      const userCount = await prisma.cuentas.count();
      console.log(`✅ Tabla cuentas accesible - ${userCount} usuarios registrados`);
    } catch (error) {
      console.log('⚠️  Tablas no encontradas - ejecuta: npm run db:push');
    }

    // Test 4: Verificar variables de entorno
    console.log('4. Verificando variables de entorno...');
    const requiredEnvVars = ['DATABASE_URL', 'JWT_SECRET'];
    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      console.log(`❌ Variables de entorno faltantes: ${missingVars.join(', ')}`);
      return false;
    } else {
      console.log('✅ Variables de entorno configuradas correctamente');
    }

    console.log('\n🎉 Configuración verificada exitosamente!');
    console.log('\n📋 Próximos pasos sugeridos:');
    console.log('- npm run db:seed (poblar con datos iniciales)');
    console.log('- npm run dev (iniciar servidor)');
    console.log('- npm run db:studio (abrir GUI de base de datos)');
    
    return true;

  } catch (error) {
    console.error('❌ Error durante la verificación:', error.message);
    return false;
  } finally {
    await prisma.$disconnect();
  }
}

// Función para mostrar información del proyecto
function showProjectInfo() {
  console.log('\n📊 Información del Proyecto');
  console.log('═══════════════════════════');
  console.log(`🏷️  Nombre: ${require('./package.json').name}`);
  console.log(`📦 Versión: ${require('./package.json').version}`);
  console.log(`🗄️  Base de datos: PostgreSQL + Prisma`);
  console.log(`🌐 Puerto: ${process.env.PORT || 3001}`);
  console.log(`🔧 Entorno: ${process.env.NODE_ENV || 'development'}`);
  
  console.log('\n🛠️  Scripts disponibles:');
  const scripts = require('./package.json').scripts;
  Object.entries(scripts).forEach(([name, command]) => {
    if (name.startsWith('db:') || ['dev', 'start'].includes(name)) {
      console.log(`   npm run ${name.padEnd(12)} # ${command}`);
    }
  });
}

// Ejecutar verificación si se llama directamente
if (require.main === module) {
  showProjectInfo();
  verifySetup().then(success => {
    process.exit(success ? 0 : 1);
  });
}

module.exports = { verifySetup, showProjectInfo };
