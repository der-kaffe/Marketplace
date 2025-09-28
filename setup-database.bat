@echo off
title Marketplace - Poblar Base de Datos
color 0A

echo.
echo ================================================
echo        MARKETPLACE - POBLAR BASE DE DATOS
echo        Universidad Catolica de Temuco
echo ================================================
echo.

REM Cambiar al directorio del servidor
cd /d "c:\Users\Administrador\Documents\gitkraken\Marketplace\server"

echo [INFO] Ejecutando script de poblacion de base de datos...
echo.

REM Ejecutar el script
node scripts/populate-database.js

echo.
echo [INFO] Script completado
pause
