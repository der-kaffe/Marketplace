#!/usr/bin/env node
// scripts/generate-jwt-secrets.js

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

console.log('🔐 Generador de JWT Secrets Seguros\n');

// Generar secrets criptográficamente seguros
const jwtSecret = crypto.randomBytes(64).toString('hex');
const jwtRefreshSecret = crypto.randomBytes(64).toString('hex');

console.log('✅ Secrets generados:');
console.log('\n📋 Copia estas líneas a tu archivo .env:\n');

console.log('# JWT Configuration - Secrets seguros generados automáticamente');
console.log(`JWT_SECRET=${jwtSecret}`);
console.log(`JWT_REFRESH_SECRET=${jwtRefreshSecret}`);
console.log('JWT_EXPIRES_IN=15m');
console.log('JWT_REFRESH_EXPIRES_IN=7d');

console.log('\n⚠️  IMPORTANTE:');
console.log('- Nunca compartas estos secrets');
console.log('- Usa secrets diferentes para desarrollo y producción');
console.log('- Regenera los secrets si sospechas que han sido comprometidos');

// Opcionalmente, crear un archivo .env.security con los nuevos secrets
const envSecurityPath = path.join(__dirname, '..', '.env.security');
const envContent = `# JWT Configuration - Secrets seguros
# Generado el: ${new Date().toISOString()}
JWT_SECRET=${jwtSecret}
JWT_REFRESH_SECRET=${jwtRefreshSecret}
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# INSTRUCCIONES:
# 1. Copia estas líneas a tu archivo .env
# 2. Elimina este archivo después de copiar
# 3. Nunca commitees este archivo a git
`;

fs.writeFileSync(envSecurityPath, envContent);
console.log(`\n💾 Archivo creado: ${envSecurityPath}`);
console.log('   Puedes copiar desde ahí y luego eliminarlo.');
