//products.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 📸 Ruta para servir imágenes desde la BD
router.get('/images/:productoId/:imagenId', async (req, res) => {
  try {
    const { productoId, imagenId } = req.params;
    
    const imagen = await prisma.imagenesProducto.findFirst({
      where: {
        id: parseInt(imagenId),
        productoId: parseInt(productoId)
      }
    });

    if (!imagen) {
      return res.status(404).json({ ok: false, message: 'Imagen no encontrada' });
    }

    // Si tiene imagenData en BD, servirla
    if (imagen.imagenData) {
      const mimeType = imagen.mimeType || 'image/jpeg';
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache 1 año
      return res.send(Buffer.from(imagen.imagenData));
    }

    // Si solo tiene URL (compatibilidad), redirigir o servir archivo estático
    if (imagen.urlImagen) {
      // Retornar URL para que el cliente la use
      return res.json({ ok: true, url: imagen.urlImagen });
    }

    return res.status(404).json({ ok: false, message: 'Imagen sin datos' });
  } catch (error) {
    console.error('Error sirviendo imagen:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// GET /api/products - Listar productos
router.get('/', async (req, res) => {
  try {
    const { category, search, page = 1, limit = 20 } = req.query;
    
    // ✅ SOLUCIÓN 1: Validar página mínima
    const currentPage = Math.max(1, parseInt(page) || 1);
    const currentLimit = Math.max(1, Math.min(100, parseInt(limit) || 20));
    
    //console.log(`📊 Obteniendo productos - Página: ${currentPage}, Límite: ${currentLimit}`);
    
    // Construir filtros para la nueva estructura
    const where = {
      estadoId: 1 // Solo productos disponibles
    };
    
    if (category) {
      where.categoria = {
        nombre: { contains: category, mode: 'insensitive' }
      };
    }
    
    if (search) {
      where.OR = [
        { nombre: { contains: search, mode: 'insensitive' } },
        { descripcion: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    // ✅ SOLUCIÓN 2: Skip siempre positivo
    const skip = Math.max(0, (currentPage - 1) * currentLimit);
    
    //console.log(`🔢 Calculando skip: ${skip} = (${currentPage} - 1) * ${currentLimit}`);

    // Verificamos si hay usuario autenticado
    const user = req.user; // viene desde middleware de auth

    // Base: solo productos activos
    const whereClause = {
      ...where, // mantiene filtros de categoría, búsqueda y estadoId
    };

    // Añadir reglas según tipo de usuario
    if (!user) {
      // Usuario no logeado → solo visibles
      whereClause.visible = true;
    } else if (user.role === "CLIENTE") {
      whereClause.visible = true;
    } else if (user.role === "VENDEDOR") {
      whereClause.vendedorId = user.userId;
    } else if (user.role === "ADMIN") {
      // Admin ve todo
    }

    // Obtener productos con información del vendedor y categoría
    const products = await prisma.productos.findMany({
      where: whereClause,
      include: {
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            campus: true,
            reputacion: true
          }
        },
        categoria: true,
        estado: true,
        imagenes: true
      },
      orderBy: [
        { fechaAgregado: 'desc' }
      ],
      skip,
      take: currentLimit
    });

    // Obtener total para paginación
    const total = await prisma.productos.count({ where: whereClause });

    //console.log(`✅ Productos encontrados: ${products.length}/${total}`);

    // ✅ SOLUCIÓN 3: Conversión segura de tipos
    const formattedProducts = products.map(product => ({
      id: product.id,
      nombre: product.nombre,
      descripcion: product.descripcion,
      // ✅ Conversión segura de Decimal a number
      precioAnterior: product.precioAnterior ? Number(product.precioAnterior) : null,
      precioActual: product.precioActual ? Number(product.precioActual) : null,
      categoria: product.categoria?.nombre,
      // ✅ Conversión segura de calificación
      calificacion: product.calificacion ? Number(product.calificacion) : null,
      cantidad: product.cantidad,
      estado: product.estado.nombre,
      fechaAgregado: product.fechaAgregado,
      imagenes: product.imagenes.map(img => ({
        id: img.id,
        // Si tiene imagenData, crear URL absoluta para obtenerla desde BD
        urlImagen: img.imagenData 
          ? `${req.protocol}://${req.get('host')}/api/products/images/${product.id}/${img.id}`
          : img.urlImagen,
        tieneImagenData: !!img.imagenData
      })),
      // 👇 Nuevos campos
      informacionTecnica: product.informacionTecnica,
      estadoProducto: product.estadoProducto,
      tiempoUso: product.tiempoUso,
      vendedor: {
        id: product.vendedor.id,
        nombre: product.vendedor.nombre,
        apellido: product.vendedor.apellido,
        correo: product.vendedor.correo,
        campus: product.vendedor.campus,
        // ✅ Conversión segura de reputación
        reputacion: product.vendedor.reputacion ? Number(product.vendedor.reputacion) : 0
      }
    }));

    res.json({
      ok: true,
      products: formattedProducts,
      pagination: {
        page: currentPage,
        limit: currentLimit,
        total,
        totalPages: Math.max(1, Math.ceil(total / currentLimit))
      }
    });

  } catch (error) {
    console.error('❌ Error listando productos:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});
// GET /api/products/my-products - Listar productos del vendedor autenticado
router.get('/my-products', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    
    const currentPage = Math.max(1, parseInt(page) || 1);
    const currentLimit = Math.max(1, Math.min(100, parseInt(limit) || 20));
    const skip = Math.max(0, (currentPage - 1) * currentLimit);

    // Filtrar productos por el ID del usuario autenticado
    const whereClause = {
      vendedorId: req.user.userId
    };

    // Obtener productos del vendedor
    const [products, total] = await prisma.$transaction([
      prisma.productos.findMany({
        where: whereClause,
        include: {
          categoria: true,
          estado: true,
          imagenes: true,
          vendedor: {
            select: { id: true, nombre: true, apellido: true }
          }
        },
        orderBy: { fechaAgregado: 'desc' },
        skip,
        take: currentLimit
      }),
      prisma.productos.count({ where: whereClause })
    ]);

    // Formatear productos para una respuesta consistente
    const formattedProducts = products.map(product => ({
      id: product.id,
      nombre: product.nombre,
      descripcion: product.descripcion,
      precioAnterior: product.precioAnterior ? Number(product.precioAnterior) : null,
      precioActual: product.precioActual ? Number(product.precioActual) : null,
      categoria: product.categoria?.nombre,
      calificacion: product.calificacion ? Number(product.calificacion) : null,
      cantidad: product.cantidad,
      estado: product.estado.nombre,
      visible: product.visible,
      fechaAgregado: product.fechaAgregado,
      imagenes: product.imagenes.map(img => ({
        id: img.id,
        // Si tiene imagenData, crear URL absoluta para obtenerla desde BD
        urlImagen: img.imagenData 
          ? `${req.protocol}://${req.get('host')}/api/products/images/${product.id}/${img.id}`
          : img.urlImagen,
        tieneImagenData: !!img.imagenData
      })),
      // 👇 Nuevos campos
      informacionTecnica: product.informacionTecnica,
      estadoProducto: product.estadoProducto,
      tiempoUso: product.tiempoUso,
      vendedor: product.vendedor
    }));

    res.json({
      ok: true,
      products: formattedProducts,
      pagination: {
        page: currentPage,
        limit: currentLimit,
        total,
        totalPages: Math.ceil(total / currentLimit)
      }
    });

  } catch (error) {
    console.error('❌ Error listando mis productos:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// GET /api/products/:id - Obtener producto por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const product = await prisma.productos.findUnique({
      where: { 
        id: parseInt(id)
      },
      include: {
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            campus: true,
            reputacion: true
          }
        },
        categoria: true,
        estado: true,
        imagenes: true
      }
    });

    if (!product || product.estadoId !== 1) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    // ✅ SOLUCIÓN 4: Conversión segura para producto individual
    const formattedProduct = {
      id: product.id,
      nombre: product.nombre,
      descripcion: product.descripcion,
      precioAnterior: product.precioAnterior ? Number(product.precioAnterior) : null,
      precioActual: product.precioActual ? Number(product.precioActual) : null,
      categoria: product.categoria?.nombre,
      calificacion: product.calificacion ? Number(product.calificacion) : null,
      cantidad: product.cantidad,
      estado: product.estado.nombre,
      fechaAgregado: product.fechaAgregado,
      imagenes: product.imagenes.map(img => ({
        id: img.id,
        // Si tiene imagenData, crear URL absoluta para obtenerla desde BD
        urlImagen: img.imagenData 
          ? `${req.protocol}://${req.get('host')}/api/products/images/${product.id}/${img.id}`
          : img.urlImagen,
        tieneImagenData: !!img.imagenData
      })),
      // 👇 Nuevos campos
      informacionTecnica: product.informacionTecnica,
      estadoProducto: product.estadoProducto,
      tiempoUso: product.tiempoUso,
      vendedor: {
        ...product.vendedor,
        reputacion: product.vendedor.reputacion ? Number(product.vendedor.reputacion) : 0
      }
    };

    res.json({
      ok: true,
      product: formattedProduct
    });

  } catch (error) {
    console.error('❌ Error obteniendo producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// POST /api/products - Crear producto (CON AUTO-PROMOCIÓN A VENDEDOR)
router.post('/', authenticateToken, [
  body('nombre').isLength({ min: 3 }).withMessage('Nombre debe tener al menos 3 caracteres'),
  body('descripcion').isLength({ min: 10 }).withMessage('Descripción debe tener al menos 10 caracteres'),
  body('precioActual').isFloat({ min: 0 }).withMessage('Precio debe ser un número positivo'),
  body('categoriaId').isInt({ min: 1 }).withMessage('Debe seleccionar una categoría válida')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        ok: false,
        message: 'Datos de entrada inválidos',
        errors: errors.array()
      });
    }

    const { 
      nombre, 
      descripcion, 
      precioAnterior, 
      precioActual,
      categoriaId,
      cantidad,
      imageUrl, // <-- Recibe imageUrl del body (compatibilidad)
      imagenes, // <-- Recibe múltiples imágenes
      informacionTecnica,
      estadoProducto, // 'nuevo' o 'usado'
      tiempoUso
    } = req.body;

    // ✅ PASO 1: Verificar que la categoría existe
    const categoria = await prisma.categorias.findUnique({
      where: { id: parseInt(categoriaId) }
    });

    if (!categoria) {
      return res.status(400).json({
        ok: false,
        message: 'Categoría no encontrada'
      });
    }

    // ✅ PASO 2: Obtener usuario actual con su rol
    const usuario = await prisma.cuentas.findUnique({
      where: { id: req.user.userId },
      include: { rol: true }
    });

    if (!usuario) {
      return res.status(404).json({
        ok: false,
        message: 'Usuario no encontrado'
      });
    }

    // ✅ PASO 3: Auto-promoción a VENDEDOR si es CLIENTE
    let roleChanged = false;
    if (usuario.rol.nombre.toUpperCase() === 'CLIENTE') {
      // Buscar el rol de VENDEDOR en la BD
      const rolVendedor = await prisma.roles.findFirst({
        where: { nombre: { equals: 'Vendedor', mode: 'insensitive' } }
      });

      if (!rolVendedor) {
        return res.status(500).json({
          ok: false,
          message: 'Error: Rol de vendedor no encontrado en el sistema'
        });
      }

      // Actualizar rol del usuario a VENDEDOR
      await prisma.cuentas.update({
        where: { id: usuario.id },
        data: { rolId: rolVendedor.id }
      });

      roleChanged = true;
      console.log(`✅ Usuario ${usuario.usuario} promovido a VENDEDOR`);
    }

    // ✅ PASO 4: Crear el producto
    const newProduct = await prisma.productos.create({
      data: {
        nombre,
        descripcion,
        precioAnterior: precioAnterior ? parseFloat(precioAnterior) : null,
        precioActual: parseFloat(precioActual),
        categoriaId: parseInt(categoriaId),
        vendedorId: req.user.userId,
        cantidad: cantidad ? parseInt(cantidad) : 1,
        estadoId: 1, // Estado "Disponible"
        visible: true, // Visible por defecto
        calificacion: 0.0,
        // 👇 Nuevos campos
        informacionTecnica: informacionTecnica || null,
        estadoProducto: estadoProducto || null, // 'nuevo' o 'usado'
        tiempoUso: tiempoUso || null
      },
      include: {
        categoria: true,
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            usuario: true
          }
        },
        estado: true
      }
    });    // 🖼️ PASO 5: Manejar múltiples imágenes
    const imagenesLista = imagenes && Array.isArray(imagenes) ? imagenes : (imageUrl ? [imageUrl] : []);
    
    if (imagenesLista.length > 0) {
      console.log(`📷 Procesando ${imagenesLista.length} imagen(es) para producto ${newProduct.id}`);
      
      for (let i = 0; i < imagenesLista.length; i++) {
        const imagenItem = imagenesLista[i];
        
        try {
          if (typeof imagenItem === 'string') {
            if (imagenItem.startsWith('data:image')) {
              // 📸 Procesar imagen base64
              const base64Match = imagenItem.match(/^data:([^;]+);base64,(.+)$/);
              if (base64Match) {
                const mimeType = base64Match[1];
                const base64Data = base64Match[2];
                const imageBuffer = Buffer.from(base64Data, 'base64');
                
                // Validar tamaño de imagen (máx 10MB)
                if (imageBuffer.length > 10 * 1024 * 1024) {
                  console.warn(`⚠️ Imagen ${i+1} muy grande: ${imageBuffer.length} bytes`);
                  continue;
                }
                
                await prisma.imagenesProducto.create({
                  data: {
                    productoId: newProduct.id,
                    imagenData: imageBuffer,
                    mimeType: mimeType,
                    urlImagen: null
                  }
                });
                
                console.log(`✅ Imagen ${i+1} guardada: ${mimeType}, ${imageBuffer.length} bytes`);
              }
            } else {
              // 🔗 URL (compatibilidad hacia atrás)
              await prisma.imagenesProducto.create({
                data: {
                  productoId: newProduct.id,
                  urlImagen: imagenItem,
                  imagenData: null,
                  mimeType: null
                }
              });
              console.log(`✅ Imagen ${i+1} URL guardada: ${imagenItem}`);
            }
          } else if (imagenItem && imagenItem.imageData) {
            // 📦 Objeto con imageData y mimeType
            const imageBuffer = Buffer.from(imagenItem.imageData, 'base64');
            
            if (imageBuffer.length > 10 * 1024 * 1024) {
              console.warn(`⚠️ Imagen objeto ${i+1} muy grande: ${imageBuffer.length} bytes`);
              continue;
            }
              await prisma.imagenesProducto.create({
              data: {
                productoId: newProduct.id,
                imagenData: imageBuffer,
                mimeType: imagenItem.mimeType || 'image/jpeg',
                urlImagen: null
              }
            });
            
            console.log(`✅ Imagen objeto ${i+1} guardada: ${imagenItem.mimeType}, ${imageBuffer.length} bytes`);
          }
        } catch (imgError) {
          console.error(`❌ Error procesando imagen ${i+1}:`, imgError);
        }
      }
    }

    // ✅ PASO 5: Respuesta exitosa
    res.status(201).json({
      ok: true,
      message: roleChanged 
        ? '🎉 ¡Producto creado! Ahora eres VENDEDOR' 
        : 'Producto creado exitosamente',
      roleChanged,
      newRole: roleChanged ? 'VENDEDOR' : usuario.rol.nombre.toUpperCase(),
      product: {
        id: newProduct.id,
        nombre: newProduct.nombre,
        descripcion: newProduct.descripcion,
        precioActual: Number(newProduct.precioActual),
        precioAnterior: newProduct.precioAnterior ? Number(newProduct.precioAnterior) : null,
        categoria: newProduct.categoria?.nombre,
        cantidad: newProduct.cantidad,
        visible: newProduct.visible,
        vendedor: newProduct.vendedor
      }
    });

  } catch (error) {
    console.error('❌ Error creando producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/products/categories - Obtener categorías
router.get('/categories/list', async (req, res) => {
  try {
    const categories = await prisma.categorias.findMany({
      orderBy: {
        nombre: 'asc'
      },
      include: {
        subcategorias: true,
        categoriaPadre: true
      }
    });

    res.json({
      ok: true,
      categories: categories.map(cat => ({
        id: cat.id,
        nombre: cat.nombre,
        categoriaPadreId: cat.categoriaPadreId,
        subcategorias: cat.subcategorias?.map(sub => ({
          id: sub.id,
          nombre: sub.nombre
        })) || []
      }))
    });

  } catch (error) {
    console.error('❌ Error obteniendo categorías:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor'
    });
  }
});

// Cambiar visibilidad del producto
router.patch("/:id/visibility", authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { visible } = req.body;

    const producto = await prisma.productos.findUnique({
      where: { id: parseInt(id) },
    });

    if (typeof visible !== "boolean") {
      return res.status(400).json({ ok: false, message: "El valor de 'visible' debe ser booleano (true o false)" });
    }

    if (!producto) {
      return res.status(404).json({ ok: false, message: "Producto no encontrado" });
    }

    // Solo el vendedor o admin puede cambiar visibilidad
    if (producto.vendedorId !== req.user.userId && req.user.role !== "ADMIN") {
      return res
        .status(403)
        .json({ ok: false, message: "No tienes permiso para modificar este producto" });
    }

    const actualizado = await prisma.productos.update({
      where: { id: parseInt(id) },
      data: { visible },
    });

    res.json({ ok: true, message: "Visibilidad actualizada", producto: actualizado });
  } catch (error) {
    console.error("❌ Error al cambiar visibilidad:", error);
    res.status(500).json({ ok: false, message: "Error interno al cambiar visibilidad" });
  }
});

// PUT /api/products/:id - Actualizar producto completo
router.put('/:id', authenticateToken, [
  body('nombre').optional().isLength({ min: 3 }).withMessage('Nombre debe tener al menos 3 caracteres'),
  body('descripcion').optional().isLength({ min: 10 }).withMessage('Descripción debe tener al menos 10 caracteres'),
  body('precioActual').optional().isFloat({ min: 0 }).withMessage('Precio debe ser un número positivo'),
  body('categoriaId').optional().isInt({ min: 1 }).withMessage('Categoría inválida'),
  body('cantidad').optional().isInt({ min: 0 }).withMessage('Cantidad debe ser un número entero positivo')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        ok: false,
        message: 'Datos de entrada inválidos',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const { 
      nombre, 
      descripcion, 
      precioAnterior, 
      precioActual,
      categoriaId,
      cantidad,
      estadoId
    } = req.body;

    // ✅ PASO 1: Verificar que el producto existe
    const productoExistente = await prisma.productos.findUnique({
      where: { id: parseInt(id) },
      include: { vendedor: true }
    });

    if (!productoExistente) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    // ✅ PASO 2: Verificar permisos (solo el vendedor dueño o admin)
    if (productoExistente.vendedorId !== req.user.userId && req.user.role !== 'ADMIN') {
      return res.status(403).json({
        ok: false,
        message: 'No tienes permiso para modificar este producto'
      });
    }

    // ✅ PASO 3: Preparar datos de actualización
    const updateData = {};
    if (nombre !== undefined) updateData.nombre = nombre;
    if (descripcion !== undefined) updateData.descripcion = descripcion;
    if (precioAnterior !== undefined) updateData.precioAnterior = precioAnterior ? parseFloat(precioAnterior) : null;
    if (precioActual !== undefined) updateData.precioActual = parseFloat(precioActual);
    if (categoriaId !== undefined) updateData.categoriaId = parseInt(categoriaId);
    if (cantidad !== undefined) updateData.cantidad = parseInt(cantidad);
    if (estadoId !== undefined) updateData.estadoId = parseInt(estadoId);

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        ok: false,
        message: 'No se proporcionaron campos para actualizar'
      });
    }

    // ✅ PASO 4: Si se cambió la categoría, verificar que existe
    if (categoriaId) {
      const categoria = await prisma.categorias.findUnique({
        where: { id: parseInt(categoriaId) }
      });

      if (!categoria) {
        return res.status(400).json({
          ok: false,
          message: 'Categoría no encontrada'
        });
      }
    }

    // ✅ PASO 5: Actualizar producto
    const productoActualizado = await prisma.productos.update({
      where: { id: parseInt(id) },
      data: updateData,
      include: {
        categoria: true,
        vendedor: {
          select: {
            id: true,
            nombre: true,
            apellido: true,
            correo: true,
            usuario: true
          }
        },
        estado: true
      }
    });

    res.json({
      ok: true,
      message: 'Producto actualizado exitosamente',
      product: {
        id: productoActualizado.id,
        nombre: productoActualizado.nombre,
        descripcion: productoActualizado.descripcion,
        precioActual: Number(productoActualizado.precioActual),
        precioAnterior: productoActualizado.precioAnterior ? Number(productoActualizado.precioAnterior) : null,
        categoria: productoActualizado.categoria?.nombre,
        cantidad: productoActualizado.cantidad,
        visible: productoActualizado.visible,
        estado: productoActualizado.estado.nombre,
        vendedor: productoActualizado.vendedor
      }
    });

  } catch (error) {
    console.error('❌ Error actualizando producto:', error);
    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// DELETE /api/products/:id - Eliminar producto (Hard Delete)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const productoId = parseInt(id); // ⬅️ FIX 1: Definir la variable 'productoId' aquí

    // ✅ PASO 1: Verificar que el producto existe
    const producto = await prisma.productos.findUnique({
      where: { id: productoId }, // ⬅️ FIX 2: Usar 'productoId'
      include: { vendedor: true, estado: true }
    });

    if (!producto) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    // ✅ PASO 2: Verificar permisos (solo el vendedor dueño o admin)
    if (producto.vendedorId !== req.user.userId && req.user.role !== 'ADMIN') {
      return res.status(403).json({
        ok: false,
        message: 'No tienes permiso para eliminar este producto'
      });
    }

    // ✅ PASO 3: Verificar si tiene transacciones pendientes
    const transaccionesPendientes = await prisma.transacciones.findFirst({
      where: {
        productoId: productoId, // ⬅️ FIX 3: Usar 'productoId'
        estadoId: { in: [1, 2] } // Estados: Pendiente o En proceso
      }
    });

    if (transaccionesPendientes) {
      return res.status(400).json({
        ok: false,
        message: 'No se puede eliminar el producto porque tiene transacciones pendientes'
      });
    }

    // ⬇️ PASO 4 (MODIFICADO): Borrado físico (Hard Delete)
    // Esto elimina permanentemente la fila de la base de datos.
    const productoEliminado = await prisma.productos.delete({
      where: { id: productoId }, // ⬅️ FIX 4: Usar 'productoId'
    });

    // ⬇️ PASO 5 (MODIFICADO): Respuesta de éxito simple
    res.json({
      ok: true,
      message: 'Producto eliminado exitosamente',
      product: {
        id: productoEliminado.id,
        nombre: productoEliminado.nombre
      }
    });

  } catch (error) {
    console.error('❌ Error eliminando producto:', error);

    // ⚠️ IMPORTANTE: Manejo de error de borrado
    // Si el producto está en favoritos, reportes, etc.,
    // la base de datos lanzará un error de "foreign key".
    if (error.code === 'P2003') {
       return res.status(400).json({
         ok: false,
         message: 'No se puede eliminar el producto porque está referenciado en otra parte (ej: transacciones, favoritos, reportes).',
         error: 'Foreign key constraint failed'
       });
    }

    res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;