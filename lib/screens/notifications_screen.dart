import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Asumo que usas go_router
// Importa tus servicios
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
// Importa formateador de fecha si lo tienes, o usa uno simple

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  final AuthService _authService =
      AuthService(); // Tu servicio de autenticación

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

// Cargar datos del backend simulado
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Llamada a la API
      final response = await _authService.apiClient.getNotifications();

      if (response['ok'] == true) {
        if (mounted) {
          setState(() {
            _notifications = response['notificaciones'] ?? [];
          });
        }
      } else {
        // Si ok es false (ej: error servidor), imprimimos el error
        print("⚠️ Error al cargar: ${response['message'] ?? 'Desconocido'}");
      }
    } catch (e) {
      print('❌ Excepción cargando notificaciones: $e');
    } finally {
      // ✨ CORRECCIÓN 2: El bloque 'finally' se ejecuta SIEMPRE.
      // Esto garantiza que el círculo de carga desaparezca.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helpers visuales
  IconData _getIconForType(String type) {
    switch (type) {
      case 'valoracion':
        return Icons.star_rounded;
      case 'mensaje':
        return Icons.chat_bubble_outline;
      case 'reporte_recibido':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'valoracion':
        return Colors.amber;
      case 'mensaje':
        return AppColors.azulPrimario;
      case 'reporte_recibido':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // Lógica de navegación al hacer click

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notificaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.azulPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final bool leido = notif['leido'] ?? true;

                        return Card(
                          elevation: leido ? 0 : 2, // Resaltar no leídos
                          color: leido ? Colors.white : Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForType(notif['tipo'])
                                  .withOpacity(0.1),
                              child: Icon(_getIconForType(notif['tipo']),
                                  color: _getColorForType(notif['tipo'])),
                            ),
                            title: Text(
                              notif['titulo'],
                              style: TextStyle(
                                fontWeight:
                                    leido ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notif['mensaje'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(
                                  // Aquí podrías usar una librería como timeago para "hace 5 min"
                                  notif['fecha'].toString().split('T')[0],
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            onTap: () => null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No tienes notificaciones recientes',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
