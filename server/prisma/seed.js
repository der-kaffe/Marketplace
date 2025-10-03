const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seeding de la base de datos...');

  try {
    // Crear roles básicos
    const adminRole = await prisma.roles.upsert({
      where: { id: 1 },
      update: {},
      create: { id: 1, nombre: 'Administrador' }
    });

    const vendedorRole = await prisma.roles.upsert({
      where: { id: 2 },
      update: {},
      create: { id: 2, nombre: 'Vendedor' }
    });

    const clienteRole = await prisma.roles.upsert({
      where: { id: 3 },
      update: {},
      create: { id: 3, nombre: 'Cliente' }
    });

    console.log('✅ Roles creados');

    // Crear estados de usuario
    const estadoActivo = await prisma.estadosUsuario.upsert({
      where: { id: 1 },
      update: {},
      create: { id: 1, nombre: 'Activo' }
    });

    const estadoInactivo = await prisma.estadosUsuario.upsert({
      where: { id: 2 },
      update: {},
      create: { id: 2, nombre: 'Inactivo' }
    });

    console.log('✅ Estados de usuario creados');

    // Crear estados de productos
    const estadoDisponible = await prisma.estadosProducto.upsert({
      where: { id: 1 },
      update: {},
      create: { id: 1, nombre: 'Disponible' }
    });

    const estadoVendido = await prisma.estadosProducto.upsert({
      where: { id: 2 },
      update: {},
      create: { id: 2, nombre: 'Vendido' }
    });

    const estadoReservado = await prisma.estadosProducto.upsert({
      where: { id: 3 },
      update: {},
      create: { id: 3, nombre: 'Reservado' }
    });

    console.log('✅ Estados de productos creados');

    // Crear estados de transacciones
    const estadoPendiente = await prisma.estadosTransaccion.upsert({
      where: { id: 1 },
      update: {},
      create: { id: 1, nombre: 'Pendiente' }
    });

    const estadoCompletada = await prisma.estadosTransaccion.upsert({
      where: { id: 2 },
      update: {},
      create: { id: 2, nombre: 'Completada' }
    });

    console.log('✅ Estados de transacciones creados');

    // Crear estados de reportes
    const estadoReportePendiente = await prisma.estadosReporte.upsert({
      where: { id: 1 },
      update: {},
      create: { id: 1, nombre: 'Pendiente' }
    });

    const estadoReporteResuelto = await prisma.estadosReporte.upsert({
      where: { id: 2 },
      update: {},
      create: { id: 2, nombre: 'Resuelto' }
    });

    console.log('✅ Estados de reportes creados');

    
    // Crear categorías principales
    await prisma.categorias.deleteMany();
    
    const categoriaElectronicos = await prisma.categorias.create({
      data: { nombre: 'Electrónicos' }
    });
    
    const categoriaLibros = await prisma.categorias.create({
      data: { nombre: 'Libros' }
    });
    
    const categoriaDeportes = await prisma.categorias.create({
      data: { nombre: 'Deportes' }
    });
    
    // Subcategorías
    await prisma.categorias.create({
      data: { nombre: 'Computadoras', categoriaPadreId: categoriaElectronicos.id }
    });
    
    await prisma.categorias.create({
      data: { nombre: 'Smartphones', categoriaPadreId: categoriaElectronicos.id }
    });
    
    await prisma.categorias.create({
      data: { nombre: 'Académicos', categoriaPadreId: categoriaLibros.id }
    });
    
    console.log('✅ Categorías creadas');
    
    // Crear usuarios
    await prisma.cuentas.deleteMany();
    
    
    const adminPassword = await bcrypt.hash('admin123', 12);
    const admin = await prisma.cuentas.create({
      data: {
        nombre: 'Administrador',
        apellido: 'Sistema',
        correo: 'admin@uct.cl',
        usuario: 'admin_uct',
        contrasena: adminPassword,
        rolId: adminRole.id,
        estadoId: estadoActivo.id,
        campus: 'Campus Temuco',
        reputacion: 5.0
      }
    });
    
    const vendorPassword = await bcrypt.hash('vendor123', 12);
    const vendor = await prisma.cuentas.create({
      data: {
        nombre: 'Juan',
        apellido: 'Pérez',
        correo: 'vendedor@uct.cl',
        usuario: 'juan_perez',
        contrasena: vendorPassword,
        rolId: vendedorRole.id,
        estadoId: estadoActivo.id,
        campus: 'Campus Temuco',
        reputacion: 4.5
      }
    });
    
    const clientPassword = await bcrypt.hash('client123', 12);
    const client = await prisma.cuentas.create({
      data: {
        nombre: 'María',
        apellido: 'González',
        correo: 'cliente@alu.uct.cl',
        usuario: 'maria_gonzalez',
        contrasena: clientPassword,
        rolId: clienteRole.id,
        estadoId: estadoActivo.id,
        campus: 'Campus Temuco',
        reputacion: 0.0
      }
    });
    
    console.log('✅ Usuarios creados');
    
// --- MENSAJES DE PRUEBA ---
const usuariosParaMensajes = [admin, vendor, client];

const mensajesDePrueba = [
  { remitenteId: admin.id, destinatarioId: vendor.id, contenido: "Hola Juan, ¿tienes más laptops en venta?" },
  { remitenteId: vendor.id, destinatarioId: admin.id, contenido: "Hola Admin, sí, me queda una más disponible 😉" },
  { remitenteId: client.id, destinatarioId: vendor.id, contenido: "Hola Juan, ¿el libro de cálculo sigue disponible?" },
  { remitenteId: vendor.id, destinatarioId: client.id, contenido: "Sí, María, aún lo tengo disponible 📚" },
  { remitenteId: client.id, destinatarioId: admin.id, contenido: "Admin, ¿me podrías dar más info del iPhone?" },
  { remitenteId: admin.id, destinatarioId: client.id, contenido: "Claro, está casi nuevo, lo entrego con cargador 🔌" }
];

await prisma.mensajes.createMany({
  data: mensajesDePrueba.map(m => ({ ...m, fechaEnvio: new Date() }))
});

console.log("✅ Mensajes de prueba creados");

    // Crear productos de ejemplo
    const subComputadoras = await prisma.categorias.create({
      data: { nombre: 'Computadoras', categoriaPadreId: categoriaElectronicos.id }
    });

    const subSmartphones = await prisma.categorias.create({
      data: { nombre: 'Smartphones', categoriaPadreId: categoriaElectronicos.id }
    });

    const subAcademicos = await prisma.categorias.create({
      data: { nombre: 'Académicos', categoriaPadreId: categoriaLibros.id }
    });


    const productos = [
      {
        nombre: 'Laptop Dell Inspiron 15',
        categoriaId: subComputadoras.id,
        vendedorId: vendor.id,
        precioAnterior: 900000,
        precioActual: 850000,
        descripcion: 'Laptop en excelente estado...',
        calificacion: 4.5,
        cantidad: 1,
        estadoId: estadoDisponible.id
      },
      {
        nombre: 'iPhone 12 64GB',
        categoriaId: subSmartphones.id,
        vendedorId: admin.id,
        precioAnterior: 700000,
        precioActual: 650000,
        descripcion: 'iPhone 12 en muy buen estado...',
        calificacion: 4.8,
        cantidad: 1,
        estadoId: estadoDisponible.id
      },
      {
        nombre: 'Cálculo: Una Variable - James Stewart',
        categoriaId: subAcademicos.id,
        vendedorId: vendor.id,
        precioAnterior: 50000,
        precioActual: 45000,
        descripcion: 'Libro de cálculo en excelente estado...',
        calificacion: 4.2,
        cantidad: 1,
        estadoId: estadoDisponible.id
      }
    ];

    for (const producto of productos) {
      await prisma.productos.create({ data: producto });
    }

    console.log('✅ Productos de ejemplo creados');

    // Crear resúmenes de usuario
    await prisma.resumenUsuario.create({
      data: {
        usuarioId: vendor.id,
        totalProductos: 2,
        totalVentas: 0,
        totalCompras: 0,
        promedioCalificacion: 4.5
      }
    });

    await prisma.resumenUsuario.create({
      data: {
        usuarioId: admin.id,
        totalProductos: 1,
        totalVentas: 0,
        totalCompras: 0,
        promedioCalificacion: 4.8
      }
    });

    await prisma.resumenUsuario.create({
      data: {
        usuarioId: client.id,
        totalProductos: 0,
        totalVentas: 0,
        totalCompras: 0,
        promedioCalificacion: 0.0
      }
    });

    console.log('✅ Resúmenes de usuario creados');

    // Crear 50 usuarios de prueba @alu.uct.cl
    const usuariosDePrueba = [];
    for (let i = 1; i <= 50; i++) {
      const password = await bcrypt.hash('test1234', 12);
      usuariosDePrueba.push({
        nombre: `Usuario${i}`,
        apellido: `Apellido${i}`,
        correo: `usuario${i}@alu.uct.cl`,
        usuario: `usuario${i}`,
        contrasena: password,
        rolId: clienteRole.id,
        estadoId: estadoActivo.id,
        campus: 'Campus Temuco',
        reputacion: parseFloat((Math.random() * 5).toFixed(2))
      });
    }

    await prisma.cuentas.createMany({
      data: usuariosDePrueba,
      skipDuplicates: true,
    });

    console.log('✅ 50 usuarios de prueba creados');

    // Crear 100 publicaciones realistas

    const usuarios = await prisma.cuentas.findMany({
      select: { id: true }
    });

    const publicaciones = [];
    for (let i = 1; i <= 100; i++) {
      const randomUser = usuarios[Math.floor(Math.random() * usuarios.length)];
      publicaciones.push({
        titulo: `Publicación ${i}`,
        cuerpo: `Esta es una publicación de ejemplo número ${i}. Información interesante sobre productos o servicios.`,
        usuarioId: randomUser.id,
        estado: 'Activa',
        fecha: new Date()
      });
    }


    await prisma.publicaciones.createMany({
      data: publicaciones,
    });

    console.log('✅ 100 publicaciones creadas');

    console.log('\n🎉 Seeding completado exitosamente!');
    console.log('\n📋 Usuarios creados:');
    console.log('👤 Admin: admin@uct.cl / admin123');
    console.log('🛒 Vendedor: vendedor@uct.cl / vendor123');
    console.log('👥 Cliente: cliente@alu.uct.cl / client123');

  } catch (error) {
    console.error('❌ Error durante el seeding:', error);
    throw error;
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
