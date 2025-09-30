#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Configurando PostgreSQL con Prisma...\n');

// Función para ejecutar comandos
function runCommand(command, description) {
  console.log(`📋 ${description}...`);
  try {
    execSync(command, { stdio: 'inherit' });
    console.log(`✅ ${description} completado\n`);
  } catch (error) {
    console.error(`❌ Error en: ${description}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Verificar si existe .env
function setupEnvFile() {
  const envPath = path.join(__dirname, '.env');
  const envExamplePath = path.join(__dirname, '.env.example');
  
  if (!fs.existsSync(envPath)) {
    if (fs.existsSync(envExamplePath)) {
      console.log('📄 Creando archivo .env desde .env.example...');
      fs.copyFileSync(envExamplePath, envPath);
      console.log('✅ Archivo .env creado');
      console.log('⚠️  IMPORTANTE: Edita el archivo .env con tu configuración de PostgreSQL\n');
    } else {
      console.log('❌ No se encontró .env.example');
      process.exit(1);
    }
  } else {
    console.log('✅ Archivo .env ya existe\n');
  }
}

// Función principal
async function main() {
  try {
    // Verificar Node.js
    console.log('🔍 Verificando Node.js...');
    const nodeVersion = process.version;
    console.log(`✅ Node.js ${nodeVersion} detectado\n`);

    // Instalar dependencias
    runCommand('npm install', 'Instalando dependencias');

    // Configurar .env
    setupEnvFile();

    // Generar cliente de Prisma
    runCommand('npx prisma generate', 'Generando cliente de Prisma');

    console.log('🎉 Configuración completada!\n');
    console.log('📋 Próximos pasos:');
    console.log('1. Edita el archivo .env con tu configuración de PostgreSQL');
    console.log('2. Ejecuta: npm run db:push (para aplicar el schema)');
    console.log('3. Ejecuta: npm run db:seed (para datos iniciales)');
    console.log('4. Ejecuta: npm run dev (para iniciar el servidor)\n');
    
    console.log('💡 Comandos útiles:');
    console.log('- npm run db:studio    # Abrir GUI de base de datos');
    console.log('- npm run db:migrate   # Crear migraciones');
    console.log('- npm run dev          # Iniciar servidor\n');

  } catch (error) {
    console.error('❌ Error durante la configuración:', error.message);
    process.exit(1);
  }
}

main();
