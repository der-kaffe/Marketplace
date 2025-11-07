import 'dart:async'; // 1. Importar 'async' para el Timer
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../theme/app_colors.dart';
import 'new_post_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget? child;

  // ✅ 1. ACEPTA LA GLOBALKEY
  final GlobalKey<HomeScreenState> homeScreenKey;

  const MainScreen(
      {super.key,
      this.child,
      required this.homeScreenKey // ✅ 2. RECÍBELA EN EL CONSTRUCTOR
      });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // --- 3. Añadir estado para notificaciones ---
  Timer? _notificationTimer;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    // 4. Iniciar el sondeo de notificaciones
  }

  @override
  void dispose() {
    // 5. Cancelar el timer al salir
    _notificationTimer?.cancel();
    super.dispose();
  }

  // ✅ 4. NUEVA FUNCIÓN PARA CALCULAR EL ÍNDICE BASADO EN GOROUTER
  int _calculateCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home/messages')) return 1;
    if (location.startsWith('/home/favorites')) return 2;
    if (location.startsWith('/home/profile')) return 3;
    // Cualquier otra cosa (incluyendo /home) es 0
    return 0;
  }

  // ✅ 5. NUEVA FUNCIÓN PARA OBTENER EL TÍTULO BASADO EN GOROUTER
  String _getTitle(int currentIndex) {
    switch (currentIndex) {
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

  @override
  Widget build(BuildContext context) {
    // ✅ 6. CALCULA EL ÍNDICE ACTUAL
    final int currentIndex = _calculateCurrentIndex(context);

    //final body = widget.child ?? _screens[_currentIndex];

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
            Text(_getTitle(currentIndex),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
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

      // ✅ 8. ASIGNA EL 'widget.child' DIRECTAMENTE AL BODY
      body: widget.child,

      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
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

        // ✅ 9. IMPLEMENTA LA LÓGICA DE 'await' Y 'forceRefresh'

        onNewPost: () async {
          // Usar GoRouter para navegar y esperar el resultado
          await context.push('/new_post');

          // Siempre refresca productos al volver, sin importar cómo se regrese
          widget.homeScreenKey.currentState?.forceRefreshProducts();

          // Si el usuario estaba en otra pestaña, vuelve a Home
          if (_calculateCurrentIndex(context) != 0) {
            context.go('/home');
          }
        },
      ),
    );
  }
}
