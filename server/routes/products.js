const express = require('express');
const { body, validationResult } = require('express-validator');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { tienePalabrasProhibidas } = require('../utils/profanityFilter');

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

    if (imagen.imagenData) {
      const mimeType = imagen.mimeType || 'image/jpeg';
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'public, max-age=31536000');
      return res.send(Buffer.from(imagen.imagenData));
    }

    if (imagen.urlImagen) {
      return res.json({ ok: true, url: imagen.urlImagen });
    }

    return res.status(404).json({ ok: false, message: 'Imagen sin datos' });
  } catch (error) {
    console.error('Error sirviendo imagen:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ... (GET /api/products, GET /my-products, GET /:id, GET /categories/list, PATCH /:id/visibility)
// [Mantén todas esas rutas igual — no necesitan cambios]

// POST /api/products - Crear producto
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
      imageUrl,
      imagenes,
      informacionTecnica,
      estadoProducto,
      tiempoUso
    } = req.body;

    // 🚫 VALIDACIÓN DE LENGUAJE EN TODOS LOS CAMPOS DE TEXTO
    const checks = await Promise.all([
      tienePalabrasProhibidas(nombre),
      tienePalabrasProhibidas(descripcion),
      informacionTecnica ? tienePalabrasProhibidas(informacionTecnica) : false,
      tiempoUso ? tienePalabrasProhibidas(tiempoUso) : false
    ]);

    const [nombreMalo, descripcionMala, infoTecnicaMala, tiempoUsoMalo] = checks;

    if (nombreMalo || descripcionMala || infoTecnicaMala || tiempoUsoMalo) {
      return res.status(400).json({
        ok: false,
        message: 'Tu publicación contiene texto no permitido y ha sido bloqueada.'
      });
    }

    // ✅ PASO 1: Verificar categoría
    const categoria = await prisma.categorias.findUnique({
      where: { id: parseInt(categoriaId) }
    });
    if (!categoria) {
      return res.status(400).json({ ok: false, message: 'Categoría no encontrada' });
    }

    // ✅ PASO 2: Obtener usuario
    const usuario = await prisma.cuentas.findUnique({
      where: { id: req.user.userId },
      include: { rol: true }
    });
    if (!usuario) {
      return res.status(404).json({ ok: false, message: 'Usuario no encontrado' });
    }

    // ✅ PASO 3: Auto-promoción a VENDEDOR
    let roleChanged = false;
    if (usuario.rol.nombre.toUpperCase() === 'CLIENTE') {
      const rolVendedor = await prisma.roles.findFirst({
        where: { nombre: { equals: 'Vendedor', mode: 'insensitive' } }
      });
      if (!rolVendedor) {
        return res.status(500).json({ ok: false, message: 'Error: Rol de vendedor no encontrado' });
      }
      await prisma.cuentas.update({ where: { id: usuario.id }, data: { rolId: rolVendedor.id } });
      roleChanged = true;
      console.log(`✅ Usuario ${usuario.usuario} promovido a VENDEDOR`);
    }

    // ✅ PASO 4: Crear producto
    const newProduct = await prisma.productos.create({
      data: {
        nombre,
        descripcion,
        precioAnterior: precioAnterior ? parseFloat(precioAnterior) : null,
        precioActual: parseFloat(precioActual),
        categoriaId: parseInt(categoriaId),
        vendedorId: req.user.userId,
        cantidad: cantidad ? parseInt(cantidad) : 1,
        estadoId: 1,
        visible: true,
        calificacion: 0.0,
        // 👇 Campos nuevos con validación
        informacionTecnica: informacionTecnica || null,
        estadoProducto: estadoProducto || null,
        tiempoUso: tiempoUso || null
      },
      include: {
        categoria: true,
        vendedor: { select: { id: true, nombre: true, correo: true, usuario: true } },
        estado: true
      }
    });

    // 🖼️ PASO 5: Manejar imágenes
    const imagenesLista = imagenes && Array.isArray(imagenes) ? imagenes : (imageUrl ? [imageUrl] : []);
    if (imagenesLista.length > 0) {
      console.log(`📷 Procesando ${imagenesLista.length} imagen(es) para producto ${newProduct.id}`);
      for (let i = 0; i < imagenesLista.length; i++) {
        const imagenItem = imagenesLista[i];
        try {
          if (typeof imagenItem === 'string') {
            if (imagenItem.startsWith('data:image')) {
              const base64Match = imagenItem.match(/^data:([^;]+);base64,(.+)$/);
              if (base64Match) {
                const mimeType = base64Match[1];
                const base64Data = base64Match[2];
                const imageBuffer = Buffer.from(base64Data, 'base64');
                if (imageBuffer.length > 10 * 1024 * 1024) continue;
                await prisma.imagenesProducto.create({
                  data: { productoId: newProduct.id, imagenData: imageBuffer, mimeType: mimeType }
                });
              }
            } else {
              await prisma.imagenesProducto.create({
                data: { productoId: newProduct.id, urlImagen: imagenItem }
              });
            }
          } else if (imagenItem && imagenItem.imageData) {
            const imageBuffer = Buffer.from(imagenItem.imageData, 'base64');
            if (imageBuffer.length > 10 * 1024 * 1024) continue;
            await prisma.imagenesProducto.create({
              data: {
                productoId: newProduct.id,
                imagenData: imageBuffer,
                mimeType: imagenItem.mimeType || 'image/jpeg'
              }
            });
          }
        } catch (imgError) {
          console.error(`❌ Error procesando imagen ${i + 1}:`, imgError);
        }
      }
    }

    // ✅ PASO 6: Respuesta exitosa
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

// PUT /api/products/:id - Actualizar producto
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
      estadoId,
      informacionTecnica, // ✅ Incluido
      tiempoUso         // ✅ Incluido
    } = req.body;

    // ✅ Verificar producto existente
    const productoExistente = await prisma.productos.findUnique({
      where: { id: parseInt(id) },
      include: { vendedor: true }
    });
    if (!productoExistente) {
      return res.status(404).json({ ok: false, message: 'Producto no encontrado' });
    }

    // ✅ Verificar permisos
    if (productoExistente.vendedorId !== req.user.userId && req.user.role !== 'ADMIN') {
      return res.status(403).json({ ok: false, message: 'No tienes permiso para modificar este producto' });
    }

    // ✅ Preparar datos de actualización (¡incluyendo nuevos campos!)
    const updateData = {};
    if (nombre !== undefined) updateData.nombre = nombre;
    if (descripcion !== undefined) updateData.descripcion = descripcion;
    if (precioAnterior !== undefined) updateData.precioAnterior = precioAnterior ? parseFloat(precioAnterior) : null;
    if (precioActual !== undefined) updateData.precioActual = parseFloat(precioActual);
    if (categoriaId !== undefined) updateData.categoriaId = parseInt(categoriaId);
    if (cantidad !== undefined) updateData.cantidad = parseInt(cantidad);
    if (estadoId !== undefined) updateData.estadoId = parseInt(estadoId);
    if (informacionTecnica !== undefined) updateData.informacionTecnica = informacionTecnica; // ✅
    if (tiempoUso !== undefined) updateData.tiempoUso = tiempoUso; // ✅

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ ok: false, message: 'No se proporcionaron campos para actualizar' });
    }

    // 🚫 VALIDACIÓN DE LENGUAJE EN TODOS LOS CAMPOS DE TEXTO ACTUALIZADOS
    const checks = await Promise.all([
      updateData.nombre ? tienePalabrasProhibidas(updateData.nombre) : false,
      updateData.descripcion ? tienePalabrasProhibidas(updateData.descripcion) : false,
      updateData.informacionTecnica !== undefined ? tienePalabrasProhibidas(updateData.informacionTecnica) : false,
      updateData.tiempoUso !== undefined ? tienePalabrasProhibidas(updateData.tiempoUso) : false
    ]);

    const [nombreMalo, descripcionMala, infoTecnicaMala, tiempoUsoMalo] = checks;

    if (nombreMalo || descripcionMala || infoTecnicaMala || tiempoUsoMalo) {
      return res.status(400).json({
        ok: false,
        message: 'El contenido actualizado contiene texto no permitido y ha sido bloqueado.'
      });
    }

    // ✅ Verificar categoría si se actualiza
    if (categoriaId) {
      const categoria = await prisma.categorias.findUnique({ where: { id: parseInt(categoriaId) } });
      if (!categoria) {
        return res.status(400).json({ ok: false, message: 'Categoría no encontrada' });
      }
    }

    // ✅ Actualizar producto
    const productoActualizado = await prisma.productos.update({
      where: { id: parseInt(id) },
      data: updateData,
      include: {
        categoria: true,
        vendedor: { select: { id: true, nombre: true, correo: true, usuario: true } },
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

// ... (DELETE /:id y otras rutas sin cambios)
// [Mantén el resto del archivo igual: GETs, PATCH visibility, DELETE]

module.exports = router;