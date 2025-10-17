# Script para iniciar el servidor de desarrollo
Write-Host "🚀 Iniciando servidor Marketplace..." -ForegroundColor Green

# Cambiar al directorio del servidor
Set-Location "C:\Users\Administrador\Documents\gitkraken\Marketplace\server"

# Verificar que node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
    npm install
}

# Verificar archivo .env
if (-not (Test-Path ".env")) {
    Write-Host "❌ Archivo .env no encontrado" -ForegroundColor Red
    Write-Host "💡 Copiando .env.example a .env..."
    Copy-Item ".env.example" ".env"
}

# Mostrar configuración
Write-Host "📋 Configuración actual:" -ForegroundColor Cyan
Write-Host "   Puerto: 3001" -ForegroundColor White
Write-Host "   Base de datos: PostgreSQL" -ForegroundColor White
Write-Host "   Entorno: development" -ForegroundColor White

# Iniciar servidor
Write-Host "🎯 Iniciando servidor en puerto 3001..." -ForegroundColor Green
Write-Host "   Health check: http://localhost:3001/api/health" -ForegroundColor Gray
Write-Host "   Presiona Ctrl+C para detener" -ForegroundColor Gray
Write-Host ""

node server.js
