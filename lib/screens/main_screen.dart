import 'dart:async'; // 1. Importar 'async' para el Timer
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart'; // 2. Importar el servicio
import '../widgets/custom_bottom_navigation.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget? child;
  const MainScreen({super.key, this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // --- 3. Añadir estado para notificaciones ---
  Timer? _notificationTimer;
  final NotificationService _notificationService = NotificationService();
  bool _hasUnreadNotifications = false;
  // ------------------------------------------

  final List<Widget> _screens = const [
    HomeScreen(),
    MessagesScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 4. Iniciar el sondeo de notificaciones
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkNotifications();
    });
    // Comprobar una vez al inicio
    _checkNotifications();
  }

  @override
  void dispose() {
    // 5. Cancelar el timer al salir
    _notificationTimer?.cancel();
    super.dispose();
  }

  /// 6. Método que llama a la API y actualiza el estado del icono
  Future<void> _checkNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();

      // Comprobamos si CUALQUIER notificación tiene 'leido' == false
      final bool hasUnread = notifications.any((notif) {
        return notif['leido'] == false;
      });

      if (mounted && hasUnread != _hasUnreadNotifications) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      print('Error en sondeo de notificaciones (MainScreen): $e');
      // No mostramos error para no ser invasivos
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.child ?? _screens[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: AppColors.blanco,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.store,
                  color: AppColors.azulPrimario, size: 24),
            ),
            const SizedBox(width: 10),
            Text(_getTitle(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          // --- 7. Modificar el IconButton para que sea un Stack ---
          IconButton(
            onPressed: () {
              // Al ir a notificaciones, actualizamos el icono
              setState(() {
                _hasUnreadNotifications = false;
              });
              context.push('/home/notifications');
            },
            icon: Stack(
              clipBehavior:
                  Clip.none, // Permite que el círculo se vea fuera del icono
              children: [
                const Icon(Icons.notifications,
                    color: AppColors.amarilloPrimario, size: 28),

                // El círculo rojo (badge)
                if (_hasUnreadNotifications)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blanco, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // -----------------------------------------------------
        ],
        elevation: 0,
      ),
      body: body,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/home/messages');
              break;
            case 2:
              context.go('/home/favorites');
              break;
            case 3:
              context.go('/home/profile');
              break;
          }
        },
        onNewPost: () {
          context.push('/new_post');
        },
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Mensajes';
      case 2:
        return 'Favoritos';
      case 3:
        return 'Perfil';
      default:
        return 'MicroMarket';
    }
  }
}
