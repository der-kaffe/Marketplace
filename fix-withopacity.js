const fs = require('fs');
const path = require('path');

// Script para reemplazar withOpacity por withValues en archivos Dart
function replaceWithOpacityInFile(filePath) {
    try {
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;
        
        // Reemplazar withOpacity por withValues
        const regex = /\.withOpacity\(([^)]+)\)/g;
        const newContent = content.replace(regex, (match, opacity) => {
            modified = true;
            return `.withValues(alpha: ${opacity})`;
        });
        
        if (modified) {
            fs.writeFileSync(filePath, newContent, 'utf8');
            console.log(`✅ Actualizado: ${filePath}`);
            return true;
        }
        
        return false;
    } catch (error) {
        console.error(`❌ Error procesando ${filePath}:`, error.message);
        return false;
    }
}

// Buscar archivos .dart recursivamente
function findDartFiles(dir) {
    let dartFiles = [];
    
    try {
        const items = fs.readdirSync(dir);
        
        for (const item of items) {
            const fullPath = path.join(dir, item);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory() && !item.startsWith('.') && item !== 'build') {
                dartFiles = dartFiles.concat(findDartFiles(fullPath));
            } else if (stat.isFile() && item.endsWith('.dart')) {
                dartFiles.push(fullPath);
            }
        }
    } catch (error) {
        console.error(`Error leyendo directorio ${dir}:`, error.message);
    }
    
    return dartFiles;
}

// Ejecutar
console.log('🔧 Reemplazando withOpacity por withValues en archivos Dart...\n');

const projectRoot = 'c:\\Users\\Administrador\\Documents\\gitkraken\\Marketplace';
const dartFiles = findDartFiles(path.join(projectRoot, 'lib'));

let modifiedFiles = 0;

console.log(`📁 Encontrados ${dartFiles.length} archivos .dart`);
console.log('🔄 Procesando archivos...\n');

for (const file of dartFiles) {
    if (replaceWithOpacityInFile(file)) {
        modifiedFiles++;
    }
}

console.log(`\n✨ Proceso completado:`);
console.log(`   📝 Archivos procesados: ${dartFiles.length}`);
console.log(`   ✅ Archivos modificados: ${modifiedFiles}`);
console.log('\n🚀 Ejecuta "flutter analyze" para verificar los cambios');
