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

// 📋 Listar todas las conversaciones de un usuario
router.get('/conversaciones', authenticateToken, async (req, res) => {
  try {
    console.log('📋 Obteniendo conversaciones para usuario:', req.user.userId);
    
    const mensajes = await prisma.Mensajes.findMany({
      where: {
        OR: [
          { remitenteId: req.user.userId },
          { destinatarioId: req.user.userId }
        ]
      },
      orderBy: { fechaEnvio: 'desc' },
      include: {
        remitente: { select: { id: true, nombre: true, usuario: true } },
        destinatario: { select: { id: true, nombre: true, usuario: true } }
      }
    });

    console.log(`📨 Total de mensajes encontrados: ${mensajes.length}`);

    // Agrupar por usuario con el que habló, asegurando que sea el último mensaje
    const conversaciones = {};
    mensajes.forEach(msg => {
      const otroUsuario = msg.remitenteId === req.user.userId ? msg.destinatario : msg.remitente;
      
      // Solo agregar si no existe o si este mensaje es más reciente
      if (!conversaciones[otroUsuario.id] || 
          new Date(msg.fechaEnvio) > new Date(conversaciones[otroUsuario.id].ultimoMensaje.fechaEnvio)) {
        conversaciones[otroUsuario.id] = {
          usuario: otroUsuario,
          ultimoMensaje: msg
        };
        
        console.log(`👤 Conversación con ${otroUsuario.nombre}: último mensaje "${msg.contenido}" del ${msg.fechaEnvio}`);
      }
    });

    const result = Object.values(conversaciones);
    console.log(`✅ Conversaciones procesadas: ${result.length}`);
    
    res.json({ ok: true, conversaciones: result });
  } catch (error) {
    console.error('Error listando conversaciones:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

module.exports = router;
