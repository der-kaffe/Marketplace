// Archivo: prisma/seed.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Iniciando seed para transacciones existentes...');

  // --- 0. Limpieza de datos de prueba (NO BORRA USUARIOS) ---
  await prisma.transacciones.deleteMany({});
  await prisma.productos.deleteMany({});
  await prisma.categorias.deleteMany({});
  await prisma.estadosProducto.deleteMany({});
  await prisma.estadosTransaccion.deleteMany({});

  // --- 1. Crear Estados Mínimos ---
  const catPruebas = await prisma.categorias.create({ data: { nombre: 'Pruebas' } });
  const estadoProdDisponible = await prisma.estadosProducto.create({ data: { nombre: 'Disponible' } });
  
  // IDs de estados que coinciden con tu backend
  const estadoTransPendiente = await prisma.estadosTransaccion.create({ 
    data: { id: 1, nombre: 'Pendiente' } 
  });
  const estadoTransCompletado = await prisma.estadosTransaccion.create({ 
    data: { id: 2, nombre: 'Completado' } 
  });

  // --- 2. ⚠️ ¡EDITA ESTO CON TUS USUARIOS! ⚠️ ---
  //
  // Cambia estos correos por los de tus usuarios de prueba.
  // Si prefieres usar el "usuario", cambia 'correo' por 'usuario'.
  //
  const CORREO_COMPRADOR = 'lm10@alu.uct.cl'; // ⬇️ REEMPLAZA ESTE
  const CORREO_VENDEDOR = 'ejaramillo2022@alu.uct.cl'; // ⬇️ REEMPLAZA ESTE
  
  console.log(`Buscando comprador: ${CORREO_COMPRADOR}`);
  const comprador = await prisma.cuentas.findUniqueOrThrow({
    where: { correo: CORREO_COMPRADOR }
  });

  console.log(`Buscando vendedor: ${CORREO_VENDEDOR}`);
  const vendedor = await prisma.cuentas.findUniqueOrThrow({
    where: { correo: CORREO_VENDEDOR }
  });

  console.log(`Usuarios encontrados: ${comprador.nombre} y ${vendedor.nombre}`);
  // --- FIN DE LA EDICIÓN ---

  // --- 3. Crear Productos de Prueba (Uno para el vendedor) ---
  const productoVendedor = await prisma.productos.create({
    data: {
      nombre: 'Producto de Prueba (Vendedor)',
      precioActual: 5000,
      cantidad: 10,
      vendedorId: vendedor.id, // ID del vendedor
      categoriaId: catPruebas.id,
      estadoId: estadoProdDisponible.id,
    },
  });

  // --- 4. Crear Transacciones de Prueba ---

  // Escenario A: Una compra para tu 'Comprador' (Pendiente de recibir)
  // El 'Comprador' verá esto en "Mis Compras" con el botón "Recibido"
  await prisma.transacciones.create({
    data: {
      productoId: productoVendedor.id,
      compradorId: comprador.id,
      vendedorId: vendedor.id,
      cantidad: 1,
      precioTotal: 5000,
      estadoId: estadoTransPendiente.id, // Pendiente
      confirmacionVendedor: true,        // El vendedor ya "entregó"
      confirmacionComprador: false,      // ¡Falta el comprador!
    },
  });

  // Escenario B: Una venta para tu 'Vendedor' (Pendiente de entregar)
  // El 'Vendedor' verá esto en "Mis Ventas" con el botón "Entregado"
  const productoComprador = await prisma.productos.create({ // Un producto que vende el "comprador"
      data: {
        nombre: 'Producto de Prueba (Comprador)',
        precioActual: 1000,
        cantidad: 1,
        vendedorId: comprador.id,
        categoriaId: catPruebas.id,
        estadoId: estadoProdDisponible.id,
      },
    });

  await prisma.transacciones.create({
    data: {
      productoId: productoComprador.id,
      compradorId: vendedor.id,    // El vendedor ahora es comprador
      vendedorId: comprador.id,    // El comprador ahora es vendedor
      cantidad: 1,
      precioTotal: 1000,
      estadoId: estadoTransPendiente.id, // Pendiente
      confirmacionVendedor: false,       // ¡Falta el vendedor! (el 'comprador' original)
      confirmacionComprador: true,       // El 'vendedor' original ya "recibió"
    },
  });

  // Escenario C: Una transacción completada
  await prisma.transacciones.create({
    data: {
      productoId: productoVendedor.id,
      compradorId: comprador.id,
      vendedorId: vendedor.id,
      cantidad: 1,
      precioTotal: 5000,
      estadoId: estadoTransCompletado.id, // Completado
      confirmacionVendedor: true,
      confirmacionComprador: true,
    },
  });

  console.log(`
  Seed completado.

  Inicia sesión con tus usuarios:
  - ${CORREO_COMPRADOR} (Verá 2 compras y 1 venta)
  - ${CORREO_VENDEDOR} (Verá 1 compra y 2 ventas)
  `);
}

main()
  .catch(async (e) => {
    console.error('Error en el seed:', e);
    await prisma.$disconnect();
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });