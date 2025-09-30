const prueba=require('prueba');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

/**
 * Script para poblar la base de datos marketplace con datos básicos
 * Incluye: roles, estados, categorías y usuarios de prueba
 */
async function populateDatabase() {
    let connection;
    
    try {
        console.log('🔗 Conectando a base de datos marketplace...');
        
        connection = await mysql.createConnection({
            host: 'localhost',
            port: 3306,
            user: 'root',
            password: '12345678',
            database: 'marketplace'
        });

        console.log('✅ Conexión exitosa');

        // === DATOS BÁSICOS ===
        
        const roles = [
            { id: 1, nombre: 'Administrador' },
            { id: 2, nombre: 'Usuario' },
            { id: 3, nombre: 'Estudiante' },
            { id: 4, nombre: 'Profesor' },
            { id: 5, nombre: 'Moderador' }
        ];

        const estadosUsuario = [
            { id: 1, nombre: 'Activo' },
            { id: 2, nombre: 'Inactivo' },
            { id: 3, nombre: 'Suspendido' },
            { id: 4, nombre: 'Pendiente' }
        ];

        const categorias = [
            { id: 1, nombre: 'Libros' },
            { id: 2, nombre: 'Electrónicos' },
            { id: 3, nombre: 'Ropa' },
            { id: 4, nombre: 'Deportes' },
            { id: 5, nombre: 'Hogar' },
            { id: 6, nombre: 'Transporte' },
            { id: 7, nombre: 'Servicios' },
            { id: 8, nombre: 'Otros' }
        ];

        const estadosProducto = [
            { id: 1, nombre: 'Disponible' },
            { id: 2, nombre: 'Vendido' },
            { id: 3, nombre: 'Reservado' },
            { id: 4, nombre: 'Pausado' },
            { id: 5, nombre: 'Eliminado' }
        ];

        const estadosTransaccion = [
            { id: 1, nombre: 'Pendiente' },
            { id: 2, nombre: 'Completada' },
            { id: 3, nombre: 'Cancelada' },
            { id: 4, nombre: 'En proceso' }
        ];

        const estadosReporte = [
            { id: 1, nombre: 'Abierto' },
            { id: 2, nombre: 'En revisión' },
            { id: 3, nombre: 'Resuelto' },
            { id: 4, nombre: 'Cerrado' }
        ];

        // === INSERTAR DATOS ===

        // Roles
        console.log('📋 Insertando roles...');
        for (const rol of roles) {
            try {
                await connection.execute(
                    'INSERT INTO roles (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [rol.id, rol.nombre]
                );
                console.log(`   ✅ ${rol.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${rol.nombre}: ${error.message}`);
            }
        }

        // Estados de usuario
        console.log('👤 Insertando estados de usuario...');
        for (const estado of estadosUsuario) {
            try {
                await connection.execute(
                    'INSERT INTO estados_usuario (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [estado.id, estado.nombre]
                );
                console.log(`   ✅ ${estado.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${estado.nombre}: ${error.message}`);
            }
        }

        // Categorías
        console.log('🏷️ Insertando categorías...');
        for (const categoria of categorias) {
            try {
                await connection.execute(
                    'INSERT INTO categorias (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [categoria.id, categoria.nombre]
                );
                console.log(`   ✅ ${categoria.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${categoria.nombre}: ${error.message}`);
            }
        }

        // Estados de producto
        console.log('📦 Insertando estados de producto...');
        for (const estado of estadosProducto) {
            try {
                await connection.execute(
                    'INSERT INTO estados_producto (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [estado.id, estado.nombre]
                );
                console.log(`   ✅ ${estado.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${estado.nombre}: ${error.message}`);
            }
        }

        // Estados de transacción
        console.log('💳 Insertando estados de transacción...');
        for (const estado of estadosTransaccion) {
            try {
                await connection.execute(
                    'INSERT INTO estados_transaccion (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [estado.id, estado.nombre]
                );
                console.log(`   ✅ ${estado.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${estado.nombre}: ${error.message}`);
            }
        }

        // Estados de reporte
        console.log('📋 Insertando estados de reporte...');
        for (const estado of estadosReporte) {
            try {
                await connection.execute(
                    'INSERT INTO estados_reporte (id, nombre) VALUES (?, ?) ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)',
                    [estado.id, estado.nombre]
                );
                console.log(`   ✅ ${estado.nombre}`);
            } catch (error) {
                console.log(`   ⚠️ Error con ${estado.nombre}: ${error.message}`);
            }
        }

        // === USUARIOS DE PRUEBA ===

        // Usuario Administrador
        console.log('👨‍💼 Creando usuario administrador...');
        const adminPassword = await bcrypt.hash('admin123', 10);
        try {
            await connection.execute(
                `INSERT INTO cuentas (nombre, apellido, correo, usuario, contrasena, rol_id, estado_id, campus, reputacion) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) 
                 ON DUPLICATE KEY UPDATE contrasena = VALUES(contrasena)`,
                ['Admin', 'Sistema', 'admin@uct.cl', 'admin', adminPassword, 1, 1, 'Temuco', 100.00]
            );
            console.log(`   ✅ admin@uct.cl / admin123`);
        } catch (error) {
            console.log(`   ⚠️ Error creando admin: ${error.message}`);
        }

        // Usuario Estudiante
        console.log('👨‍🎓 Creando usuario estudiante...');
        const studentPassword = await bcrypt.hash('123456', 10);
        try {
            await connection.execute(
                `INSERT INTO cuentas (nombre, apellido, correo, usuario, contrasena, rol_id, estado_id, campus, reputacion) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) 
                 ON DUPLICATE KEY UPDATE contrasena = VALUES(contrasena)`,
                ['Test', 'Usuario', 'test@uct.cl', 'testuser', studentPassword, 3, 1, 'Temuco', 0.00]
            );
            console.log(`   ✅ test@uct.cl / 123456`);
        } catch (error) {
            console.log(`   ⚠️ Error creando estudiante: ${error.message}`);
        }

        // === VERIFICACIÓN ===
        console.log('\n🔍 Verificando datos...');
        
        const queries = [
            { table: 'roles', desc: '📋 Roles' },
            { table: 'estados_usuario', desc: '👤 Estados usuario' },
            { table: 'categorias', desc: '🏷️ Categorías' },
            { table: 'estados_producto', desc: '📦 Estados producto' },
            { table: 'cuentas', desc: '👥 Usuarios' }
        ];

        for (const query of queries) {
            try {
                const [result] = await connection.execute(`SELECT COUNT(*) as count FROM ${query.table}`);
                console.log(`   ${query.desc}: ${result[0].count}`);
            } catch (error) {
                console.log(`   ❌ Error verificando ${query.table}: ${error.message}`);
            }
        }

        console.log('\n🎉 ¡Base de datos marketplace poblada exitosamente!');
        console.log('\n🔑 Credenciales disponibles:');
        console.log('   👨‍💼 Administrador: admin@uct.cl / admin123');
        console.log('   👨‍🎓 Estudiante: test@uct.cl / 123456');

    } catch (error) {
        console.error('❌ Error:', error.message);
        throw error;
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

// Ejecutar si es llamado directamente
if (require.main === module) {
    populateDatabase()
        .then(() => {
            console.log('\n✨ Proceso completado');
            console.log('🚀 Siguiente paso: ejecutar "test-backend.bat" para iniciar el servidor');
            process.exit(0);
        })
        .catch(error => {
            console.error('\n💥 Error:', error.message);
            process.exit(1);
        });
}

module.exports = { populateDatabase };
