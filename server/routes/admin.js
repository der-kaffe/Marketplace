// routes/admin.js
const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const bcrypt = require('bcryptjs');

// Ruta para obtener todos los usuarios
router.get('/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await prisma.cuentas.findMany({
      //orderBy: { fechaRegistro: 'desc' },
      orderBy: { id: 'asc' },
      select: {
        id: true,
        nombre: true,
        apellido: true,
        correo: true,
        usuario: true,
        rolId: true,
        estadoId: true,
        fechaRegistro: true,
        campus: true,
        reputacion: true
      }
    });

    res.json({ total: users.length, users });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error obteniendo usuarios' });
  }
});

// Eliminar usuario por id (por ahora "async", sin token)
router.delete('/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificamos si existe
    const user = await prisma.cuentas.findUnique({
      where: { id: parseInt(id) }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Eliminar
    await prisma.cuentas.delete({
      where: { id: parseInt(id) }
    });

    res.json({ success: true, message: 'Usuario eliminado correctamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error eliminando usuario' });
  }
});

// Cambiar estado (banear / desbanear)
router.patch('/users/:id/ban', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { banned } = req.body; // true o false

    // Verificar si el usuario existe
    const user = await prisma.cuentas.findUnique({
      where: { id: parseInt(id) },
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Determinar nuevo estado
    const nuevoEstado = banned ? 2 : 1; // 2 = BANEADO, 1 = ACTIVO

    // Actualizar
    const updated = await prisma.cuentas.update({
      where: { id: parseInt(id) },
      data: { estadoId: nuevoEstado },
      include: {
        estado: true,
      },
    });

    res.json({
      success: true,
      message: banned ? 'Usuario baneado' : 'Usuario desbaneado',
      user: updated,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al actualizar estado del usuario' });
  }
});

// GET /api/admin/metrics
router.get('/metrics', authenticateToken, requireAdmin, async (req, res) => {
  try {
    // Conteos básicos
    const totalUsersPromise = prisma.cuentas.count();
    const totalProductsPromise = prisma.productos.count();
    const totalPublicationsPromise = prisma.publicaciones.count();
    const totalMessagesPromise = prisma.mensajes.count();

    // Usuarios activos en 30 días (actividad_usuario)
    const since30d = new Date();
    since30d.setDate(since30d.getDate() - 30);
    const activeUsers30dPromise = prisma.actividadUsuario.count({
      where: { fecha: { gte: since30d } },
      distinct: ['usuarioId'] // count distinct usuarios que tuvieron actividad (Prisma no tiene distinct param in count; workaround below)
    }).catch(async () => {
      // Fallback: contar usuarios distintos con raw SQL
      const raw = await prisma.$queryRaw`SELECT COUNT(DISTINCT(usuario_id)) as cnt FROM actividad_usuario WHERE fecha >= NOW() - INTERVAL '30 days'`;
      return Number(raw[0]?.cnt ?? 0);
    });

    // Reportes pendientes (buscamos estado "Pendiente")
    const estadoPendiente = await prisma.estadosReporte.findFirst({
      where: { nombre: { equals: 'Pendiente', mode: 'insensitive' } }
    });

    const openReportsPromise = prisma.reportes.count({
      where: estadoPendiente ? { estadoId: estadoPendiente.id } : {}
    });

    // Transacciones completadas (buscamos estado 'Completada')
    const estadoCompletada = await prisma.estadosTransaccion.findFirst({
      where: { nombre: { equals: 'Completada', mode: 'insensitive' } }
    });
    const completedTransactionsPromise = prisma.transacciones.count({
      where: estadoCompletada ? { estadoId: estadoCompletada.id } : {}
    });

    // Mensajes últimos 7 días
    const since7d = new Date();
    since7d.setDate(since7d.getDate() - 7);
    const messagesLast7dPromise = prisma.mensajes.count({
      where: { fechaEnvio: { gte: since7d } }
    });

    // Esperar las promesas de conteo (excepto activeUsers30d que podría haber devuelto número en fallback)
    const [
      totalUsers,
      totalProducts,
      totalPublications,
      // activeUsers30d,
      openReports,
      completedTransactions,
      messagesLast7d
    ] = await Promise.all([
      totalUsersPromise,
      totalProductsPromise,
      totalPublicationsPromise,
      // activeUsers30dPromise,
      openReportsPromise,
      completedTransactionsPromise,
      messagesLast7dPromise
    ]);

    // Active users 30d: usar raw query para contar usuarios distintos por seguridad
    const activeRaw = await prisma.$queryRaw`
      SELECT COUNT(DISTINCT(usuario_id)) as cnt
      FROM actividad_usuario
      WHERE fecha >= NOW() - INTERVAL '30 days'
    `;
    const activeUsers30d = Number(activeRaw[0]?.cnt ?? 0);

    // daily new users (last 7 days) - usar raw SQL para truncar fecha
    const newUsersRaw = await prisma.$queryRaw`
      SELECT to_char(fecha_registro::date, 'YYYY-MM-DD') as day, COUNT(*) as cnt
      FROM cuentas
      WHERE fecha_registro >= NOW() - INTERVAL '6 days'
      GROUP BY day
      ORDER BY day ASC
    `;
    // newUsersRaw será un array de { day, cnt } según Postgres
    const newUsersByDay = (newUsersRaw || []).map(r => ({ day: r.day, count: Number(r.cnt) }));

    res.json({
      ok: true,
      metrics: {
        totalUsers,
        activeUsers30d,
        totalProducts,
        totalPublications,
        openReports,
        completedTransactions,
        messagesLast7d,
        newUsersByDay
      }
    });
  } catch (error) {
    console.error('Error obteniendo métricas:', error);
    res.status(500).json({ ok: false, error: 'Error interno obteniendo métricas' });
  }
});

// Crear un nuevo usuario (solo admin)
router.post('/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { nombre, apellido, correo, usuario, contrasena, rolId, campus } = req.body;

    if (!nombre || !correo || !usuario || !contrasena) {
      return res.status(400).json({ ok: false, message: 'Faltan datos obligatorios.' });
    }

    const hashedPassword = await bcrypt.hash(contrasena, 10);

    const nuevoUsuario = await prisma.cuentas.create({
      data: {
        nombre,
        apellido,
        correo,
        usuario,
        contrasena: hashedPassword,
        rolId: rolId || 3, // 3 = Cliente por defecto
        estadoId: 1,
        campus: campus || 'Campus Temuco',
      },
      include: { rol: true }
    });

    res.json({ ok: true, message: 'Usuario creado correctamente', user: nuevoUsuario });
  } catch (error) {
    console.error('❌ Error al crear usuario:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

// Actualizar un usuario (solo admin)
router.put('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, apellido, correo, usuario, rolId, campus, estadoId } = req.body;

    // Validar que el usuario exista
    const existingUser = await prisma.cuentas.findUnique({ where: { id: parseInt(id) } });
    if (!existingUser) {
      return res.status(404).json({ ok: false, message: 'Usuario no encontrado' });
    }

    const updatedUser = await prisma.cuentas.update({
      where: { id: parseInt(id) },
      data: {
        nombre,
        apellido,
        correo,
        usuario,
        rolId: rolId || existingUser.rolId,
        campus: campus ?? existingUser.campus,
        estadoId: estadoId ?? existingUser.estadoId,
      },
      include: { rol: true, estado: true },
    });

    res.json({ ok: true, message: 'Usuario actualizado correctamente', user: updatedUser });
  } catch (error) {
    console.error('❌ Error al actualizar usuario:', error);
    res.status(500).json({ ok: false, message: 'Error interno del servidor' });
  }
});

module.exports = router;