// Cargar variables de entorno
require('dotenv').config();

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

  // Crear estados de usuario (ACTIVO, BANEADO)
  await prisma.estadosUsuario.createMany({
    data: [
      { id: 1, nombre: 'ACTIVO' },
      { id: 2, nombre: 'BANEADO' },
    ],
    skipDuplicates: true,
  });

  const estadoActivo = await prisma.estadosUsuario.findUnique({ where: { id: 1 } });
  const estadoBaneado = await prisma.estadosUsuario.findUnique({ where: { id: 2 } });

  console.log('✅ Estados de usuario actualizados');

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
    const admin = await prisma.cuentas.create({      data: {
        nombre: 'Administrador Sistema',
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
    const vendor = await prisma.cuentas.create({      data: {
        nombre: 'Juan Pérez',
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
    const client = await prisma.cuentas.create({      data: {
        nombre: 'María González',
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

    console.log('✅ Resúmenes de usuario creados');    // Crear 50 usuarios de prueba @alu.uct.cl
    const usuariosDePrueba = [];
    for (let i = 1; i <= 50; i++) {
      const password = await bcrypt.hash('test1234', 12);
      usuariosDePrueba.push({
        nombre: `Usuario${i} Testeo`,
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

    // Eliminar publicaciones por defecto antes de crear nuevas publicaciones
    await prisma.publicaciones.deleteMany();
    console.log('✅ Publicaciones por defecto eliminadas');

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

    // Crear mensajes de prueba para el chat
    console.log('💬 Creando mensajes de prueba...');
    
    const mensajesPrueba = [
      {
        remitenteId: vendor.id,
        destinatarioId: client.id,
        contenido: 'Hola! ¿Te interesa la laptop Dell?',
        fechaEnvio: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 horas atrás
        leido: false
      },
      {
        remitenteId: client.id,
        destinatarioId: vendor.id,
        contenido: 'Sí, me interesa mucho. ¿Está disponible?',
        fechaEnvio: new Date(Date.now() - 90 * 60 * 1000), // 1.5 horas atrás
        leido: true
      },
      {
        remitenteId: vendor.id,
        destinatarioId: client.id,
        contenido: 'Perfecto! Sí está disponible. ¿Quieres verla en persona?',
        fechaEnvio: new Date(Date.now() - 60 * 60 * 1000), // 1 hora atrás
        leido: false
      },
      {
        remitenteId: client.id,
        destinatarioId: vendor.id,
        contenido: 'Claro, ¿dónde podemos encontrarnos?',
        fechaEnvio: new Date(Date.now() - 30 * 60 * 1000), // 30 minutos atrás
        leido: true
      },
      {
        remitenteId: vendor.id,
        destinatarioId: client.id,
        contenido: 'En el campus, cerca de la biblioteca. ¿Te parece bien a las 3pm?',
        fechaEnvio: new Date(Date.now() - 15 * 60 * 1000), // 15 minutos atrás
        leido: false
      },
      // Conversación entre admin y cliente
      {
        remitenteId: admin.id,
        destinatarioId: client.id,
        contenido: 'Hola! Veo que estás interesado en productos. ¿Necesitas ayuda?',
        fechaEnvio: new Date(Date.now() - 4 * 60 * 60 * 1000), // 4 horas atrás
        leido: true
      },
      {
        remitenteId: client.id,
        destinatarioId: admin.id,
        contenido: 'Hola admin! Sí, estoy buscando una laptop para mis estudios.',
        fechaEnvio: new Date(Date.now() - 3 * 60 * 60 * 1000), // 3 horas atrás
        leido: true
      },
      {
        remitenteId: admin.id,
        destinatarioId: client.id,
        contenido: 'Excelente! Te recomiendo revisar las ofertas de la categoría Electrónicos.',
        fechaEnvio: new Date(Date.now() - 2.5 * 60 * 60 * 1000), // 2.5 horas atrás
        leido: true
      }
    ];

    for (const mensaje of mensajesPrueba) {
      await prisma.Mensajes.create({ data: mensaje });
    }
    
    console.log('✅ Mensajes de prueba creados');
    

    // Crear reportes de ejemplo
    console.log('🐞 Creando reportes de ejemplo...');

    // Buscar algunos productos y usuarios para usar en reportes
    const laptop = await prisma.productos.findFirst({ where: { nombre: 'Laptop Dell Inspiron 15' } });
    const iphone = await prisma.productos.findFirst({ where: { nombre: 'iPhone 12 64GB' } });

    const adminUser = await prisma.cuentas.findUnique({ where: { usuario: 'admin_uct' } });
    const vendorUser = await prisma.cuentas.findUnique({ where: { usuario: 'juan_perez' } });
    const clientUser = await prisma.cuentas.findUnique({ where: { usuario: 'maria_gonzalez' } });

    const estado_Pendiente = await prisma.estadosReporte.findFirst({ where: { nombre: 'Pendiente' } });
    const estado_Resuelto = await prisma.estadosReporte.findFirst({ where: { nombre: 'Resuelto' } });

    const reportesEjemplo = [
      {
        productoId: laptop.id,
        reportanteId: clientUser.id,
        motivo: 'El producto no coincide con la descripción.',
        estadoId: estado_Pendiente.id,
      },
      {
        productoId: iphone.id,
        reportanteId: vendorUser.id,
        motivo: 'Producto defectuoso recibido.',
        estadoId: estado_Pendiente.id,
      },
      {
        usuarioReportadoId: vendorUser.id,
        reportanteId: clientUser.id,
        motivo: 'El vendedor no responde mensajes.',
        estadoId: estado_Pendiente.id,
      },
      {
        usuarioReportadoId: clientUser.id,
        reportanteId: adminUser.id,
        motivo: 'Reporte falso o mal uso de la plataforma.',
        estadoId: estado_Resuelto.id,
      }
    ];

    for (const reporte of reportesEjemplo) {
      await prisma.reportes.create({ data: reporte });
    }

    console.log('✅ Reportes de ejemplo creados');

    console.log('\n🎉 Seeding completado exitosamente!');
    console.log('\n📋 Usuarios creados:');
    console.log('👤 Admin: admin@uct.cl / admin123');
    console.log('🛒 Vendedor: vendedor@uct.cl / vendor123');
    console.log('👥 Cliente: cliente@alu.uct.cl / client123');
    console.log('💬 Usa estos usuarios para probar el chat en tiempo real!');

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
