import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    MessagesScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    // Si estamos usando go_router, el child será proporcionado por ShellRoute
    Widget body = widget.child ?? _screens[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: AppColors.blanco,
        title: Row(
          children: [
            // Logo o ícono personalizado
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.azulPrimario,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            // Título con estilo
            Text(
              _getTitle(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Botón de búsqueda
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.amarilloPrimario),
            onPressed: () {
              // Implementación futura de búsqueda
            },
          ),
          // Botón de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.amarilloPrimario),
            onPressed: () {
              // Implementación futura de notificaciones
            },
          ),
        ],
        elevation: 0, // Sin sombra
      ),
      body: body,      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Navegar usando go_router
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
