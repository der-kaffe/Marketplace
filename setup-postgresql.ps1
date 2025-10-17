# Script de configuración para PostgreSQL + Prisma
Write-Host "🚀 Configurando PostgreSQL con Prisma..." -ForegroundColor Green
Write-Host ""

# Función para verificar si un comando existe
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Verificar Node.js
Write-Host "🔍 Verificando Node.js..." -ForegroundColor Yellow
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "✅ Node.js $nodeVersion detectado" -ForegroundColor Green
} else {
    Write-Host "❌ Node.js no encontrado. Por favor instala Node.js desde https://nodejs.org" -ForegroundColor Red
    exit 1
}

# Verificar npm
if (Test-Command "npm") {
    $npmVersion = npm --version
    Write-Host "✅ npm $npmVersion detectado" -ForegroundColor Green
} else {
    Write-Host "❌ npm no encontrado" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Cambiar al directorio del servidor
$serverPath = Join-Path $PSScriptRoot "server"
if (Test-Path $serverPath) {
    Set-Location $serverPath
    Write-Host "📁 Cambiando al directorio: $serverPath" -ForegroundColor Cyan
} else {
    Write-Host "❌ Directorio 'server' no encontrado" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Instalar dependencias
Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
try {
    npm install
    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error instalando dependencias" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verificar archivo .env
$envPath = ".env"
$envExamplePath = ".env.example"

if (Test-Path $envPath) {
    Write-Host "✅ Archivo .env ya existe" -ForegroundColor Green
} elseif (Test-Path $envExamplePath) {
    Write-Host "📄 Creando archivo .env desde .env.example..." -ForegroundColor Yellow
    Copy-Item $envExamplePath $envPath
    Write-Host "✅ Archivo .env creado" -ForegroundColor Green
    Write-Host "⚠️  IMPORTANTE: Edita el archivo .env con tu configuración de PostgreSQL" -ForegroundColor Yellow
} else {
    Write-Host "❌ No se encontró .env.example" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Generar cliente de Prisma
Write-Host "⚡ Generando cliente de Prisma..." -ForegroundColor Yellow
try {
    npx prisma generate
    Write-Host "✅ Cliente de Prisma generado correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error generando cliente de Prisma" -ForegroundColor Red
    Write-Host "Asegúrate de que PostgreSQL esté corriendo y configurado correctamente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Configuración completada!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Edita el archivo .env con tu configuración de PostgreSQL" -ForegroundColor White
Write-Host "2. Ejecuta: npm run db:push (para aplicar el schema)" -ForegroundColor White
Write-Host "3. Ejecuta: npm run db:seed (para datos iniciales)" -ForegroundColor White
Write-Host "4. Ejecuta: npm run dev (para iniciar el servidor)" -ForegroundColor White
Write-Host ""
Write-Host "💡 Comandos útiles:" -ForegroundColor Cyan
Write-Host "- npm run db:studio    # Abrir GUI de base de datos" -ForegroundColor White
Write-Host "- npm run db:migrate   # Crear migraciones" -ForegroundColor White
Write-Host "- npm run dev          # Iniciar servidor" -ForegroundColor White
Write-Host ""
Write-Host "🗄️  Para PostgreSQL local puedes usar:" -ForegroundColor Cyan
Write-Host "docker run --name postgres -e POSTGRES_PASSWORD=password -d -p 5432:5432 postgres" -ForegroundColor White
Write-Host ""

# Pausa para que el usuario pueda leer
Write-Host "Presiona cualquier tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
