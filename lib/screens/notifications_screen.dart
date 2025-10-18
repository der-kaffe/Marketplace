// En /lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart'; // 1. Importar

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // ⭐️ (MODIFICADO) Solo carga notificaciones NO leídas
    try {
      var allNotifications = await _notificationService.getNotifications();

      // Filtramos para mostrar solo las 'no leídas'
      final unreadNotifications = allNotifications.where((notif) {
        return notif['leido'] == false;
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = unreadNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar notificaciones: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ⭐️ (NUEVO) Método para manejar el 'onPressed'
  Future<void> _markNotificationAsRead(int notificationId, int index) async {
    try {
      // 1. Llama a la API
      await _notificationService.markAsRead(notificationId);

      // 2. Si tiene éxito, quita la notificación de la lista local
      if (mounted) {
        setState(() {
          // Esta animación elimina el item de la lista
          _notifications.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación marcada como leída'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al marcar como leída: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconForType(String? type) {
    if (type == 'valoracion') {
      return Icons.star;
    } else if (type == 'mensaje') {
      return Icons.message;
    }
    return Icons.notifications_active;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Notificaciones'),
            ),
            body: Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 50.0,
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Notificaciones'),
              // Botón para refrescar
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadNotifications();
                  },
                ),
              ],
            ),
            body: _notifications.isEmpty
                ? const Center(child: Text('No tienes notificaciones nuevas.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final String tipo = notif['tipo'] ?? 'general';

                      return Card(
                        child: ListTile(
                          leading:
                              Icon(_getIconForType(tipo), color: Colors.amber),
                          title: Text(tipo == 'valoracion'
                              ? '¡Nueva Valoración!'
                              : 'Notificación'),
                          subtitle: Text(notif['mensaje'] ?? 'Sin mensaje'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.check, // Siempre es 'check'
                              color: Colors.green,
                            ),
                            // ⭐️ (MODIFICADO) Llama al nuevo método
                            onPressed: () {
                              _markNotificationAsRead(notif['id'], index);
                            },
                          ),
                          onTap: () {
                            // TODO: Implementar navegación
                          },
                        ),
                      );
                    },
                  ),
          );
  }
}
