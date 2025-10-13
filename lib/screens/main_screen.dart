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
    final body = widget.child ?? _screens[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: AppColors.blanco,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.store, color: AppColors.azulPrimario, size: 24),
            ),
            const SizedBox(width: 10),
            Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(icon: const Icon(Icons.search, color: AppColors.amarilloPrimario), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.amarilloPrimario),
            onPressed: () {
              context.push('/home/notifications');
            },
          ),
        ],
        elevation: 0,
      ),
      body: body,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/home/messages'); break;
            case 2: context.go('/home/favorites'); break;
            case 3: context.go('/home/profile'); break;
          }
        },
        onNewPost: () {
          // 👇 usar push para mantener el historial y que "atrás" vuelva bien
          context.push('/new_post');
        },
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Inicio';
      case 1: return 'Mensajes';
      case 2: return 'Favoritos';
      case 3: return 'Perfil';
      default: return 'MicroMarket';
    }
  }
}
