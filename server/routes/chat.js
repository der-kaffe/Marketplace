const express = require('express');
const { prisma } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 📩 Enviar mensaje
router.post('/send', authenticateToken, async (req, res) => {
  try {
    console.log('📨 Petición de envío de mensaje:', {
      body: req.body,
      user: req.user
    });

    const { destinatarioId, contenido } = req.body;

    if (!destinatarioId || !contenido) {
      return res.status(400).json({ ok: false, message: 'Faltan campos requeridos' });
    }

    const mensaje = await prisma.Mensajes.create({
      data: {
        remitenteId: req.user.userId,
        destinatarioId,
        contenido,
        tipo: 'texto'
      },
      include: {
        remitente: { select: { id: true, nombre: true, usuario: true } },
        destinatario: { select: { id: true, nombre: true, usuario: true } }
      }
    });

    res.json({ ok: true, mensaje });
  } catch (error) {
    console.error('Error enviando mensaje:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// 📥 Obtener conversación entre 2 usuarios
router.get('/conversacion/:usuarioId', authenticateToken, async (req, res) => {
  try {
    const { usuarioId } = req.params;

    const mensajes = await prisma.Mensajes.findMany({
      where: {
        OR: [
          { remitenteId: req.user.userId, destinatarioId: parseInt(usuarioId) },
          { remitenteId: parseInt(usuarioId), destinatarioId: req.user.userId }
        ]
      },
      orderBy: { fechaEnvio: 'asc' },
      include: {
        remitente: { select: { id: true, nombre: true, usuario: true } },
        destinatario: { select: { id: true, nombre: true, usuario: true } }
      }
    });

    res.json({ ok: true, mensajes });
  } catch (error) {
    console.error('Error obteniendo conversación:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// ... (tus rutas /send y /conversacion/:usuarioId)

// 📋 Listar todas las conversaciones de un usuario
router.get('/conversaciones', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId; // 1. Obtener el ID del usuario
    console.log('📋 Obteniendo conversaciones para usuario:', userId);

    // 2. ⭐️ (NUEVO) Obtener todos los conteos de no leídos en UNA sola consulta
    const unreadCounts = await prisma.Mensajes.groupBy({
      by: ['remitenteId'], // Agrupar por quién envió el mensaje
      where: {
        destinatarioId: userId, // Que yo recibí
        leido: false,           // Y que no he leído
      },
      _count: {
        id: true, // Contar los mensajes (por su ID)
      },
    });

    // 3. ⭐️ (NUEVO) Convertir el resultado en un Map para búsqueda rápida
    //    Formato de unreadCounts: [ { remitenteId: 61, _count: { id: 5 } }, ... ]
    const unreadMap = new Map();
    unreadCounts.forEach(item => {
      // Guardamos: (ID del remitente, Cuántos mensajes me envió)
      unreadMap.set(item.remitenteId, item._count.id);
    });
    console.log('📊 Mapa de no leídos:', unreadMap);


    // 4. Obtener todos los mensajes (como ya lo hacías)
    const mensajes = await prisma.Mensajes.findMany({
      where: {
        OR: [
          { remitenteId: userId },
          { destinatarioId: userId }
        ]
      },
      orderBy: { fechaEnvio: 'desc' },
      include: {
        remitente: { select: { id: true, nombre: true, usuario: true } },
        destinatario: { select: { id: true, nombre: true, usuario: true } }
      }
    });

    console.log(`📨 Total de mensajes encontrados: ${mensajes.length}`);

    // 5. Agrupar (como ya lo hacías)
    const conversaciones = {};
    mensajes.forEach(msg => {
      const otroUsuario = msg.remitenteId === userId ? msg.destinatario : msg.remitente;

      if (!conversaciones[otroUsuario.id] ||
        new Date(msg.fechaEnvio) > new Date(conversaciones[otroUsuario.id].ultimoMensaje.fechaEnvio)) {

        // Si no está en el mapa, significa que no tiene mensajes no leídos (es 0).
        const unreadCount = unreadMap.get(otroUsuario.id) || 0;

        conversaciones[otroUsuario.id] = {
          usuario: otroUsuario,
          ultimoMensaje: msg,
          unreadCount: unreadCount, // Añadir el conteo al objeto
        };

        console.log(`👤 Conversación con ${otroUsuario.nombre}: último mensaje "${msg.contenido}", no leídos: ${unreadCount}`);
      }
    });

    const result = Object.values(conversaciones);
    console.log(`✅ Conversaciones procesadas: ${result.length}`);

    // 8. Enviar el resultado con el nuevo campo 'unreadCount'
    res.json({ ok: true, conversaciones: result });

  } catch (error) {
    console.error('Error listando conversaciones:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

//  Marcar mensajes como leídos
// Al entrar a un chat, la app llamará a este endpoint
router.post('/conversacion/:usuarioId/mark-read', authenticateToken, async (req, res) => {
  try {
    const { usuarioId } = req.params; // ID del remitente (el chat que abrí)
    const userId = req.user.userId; // ID del destinatario (yo)

    console.log(`🔵 Marcando como leídos los mensajes de ${usuarioId} para ${userId}`);

    // Actualiza todos los mensajes donde yo soy el destinatario
    // y la otra persona es el remitente.
    await prisma.Mensajes.updateMany({
      where: {
        destinatarioId: userId,
        remitenteId: parseInt(usuarioId),
        leido: false
      },
      data: {
        leido: true
      }
    });

    res.json({ ok: true, message: 'Mensajes marcados como leídos' });
  } catch (error) {
    console.error('Error marcando mensajes como leídos:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

module.exports = router;