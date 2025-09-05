// main_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_bottom_navigation.dart';
// No necesitas importar las otras páginas aquí directamente

class MainScreen extends StatelessWidget {
  // Recibirá el widget hijo que debe mostrar (la pantalla actual)
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final location = GoRouterState.of(context).uri.toString();
    final isChatPage = location.startsWith('/home/chat');

    return Scaffold(
      appBar: isChatPage ? null : AppBar(title: Text(_getTitle(currentIndex))),
      body: child, // Muestra el widget hijo proporcionado por ShellRoute
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  // Función para determinar el índice basado en la ruta actual
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home/messages') ||
        location.startsWith('/home/chat')) {
      return 1;
    }
    if (location.startsWith('/home/favorites')) {
      return 2;
    }
    if (location.startsWith('/home/profile')) {
      return 3;
    }
    // Por defecto, es el home
    return 0;
  }

  // Función para navegar cuando se toca un ítem de la barra
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/home/messages');
        break;
      case 2:
        // Asumiendo que tendrás una ruta para favoritos
        // context.go('/home/favorites');
        break;
      case 3:
        // Asumiendo que tendrás una ruta para el perfil
        // context.go('/home/profile');
        break;
    }
  }

  String _getTitle(int index) {
    switch (index) {
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
