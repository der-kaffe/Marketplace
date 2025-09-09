// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/conversations_page.dart';
import '../../screens/home_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/new_post_screen.dart';
import '../../screens/startup.dart';

// Admin
import '../../screens/admin_menu_page.dart';
import '../../screens/admin_users_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/startup',
    routes: [
      GoRoute(
          path: '/startup', builder: (context, state) => const StartupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
              path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/home/messages',
              builder: (context, state) => ConversationsPage()),
          GoRoute(
              path: '/home/favorites',
              builder: (context, state) => const FavoritesScreen()),
          GoRoute(
              path: '/home/profile',
              builder: (context, state) => const ProfileScreen()),
          GoRoute(
            path: '/home/chat/:userName',
            pageBuilder: (context, state) {
              final userName = state.pathParameters['userName']!;
              final avatar = state.uri.queryParameters['avatar'] ?? '';
              return CustomTransitionPage(
                key: state.pageKey,
                child: ChatPage(userName: userName, avatar: avatar),
                transitionsBuilder: (context, animation, _, child) {
                  final tween =
                      Tween(begin: const Offset(1, 0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                      position: animation.drive(tween), child: child);
                },
              );
            },
          ),
          // 👇 Nueva ruta para crear publicación
          GoRoute(
              path: '/new_post',
              builder: (context, state) => const NewPostScreen()),
        ],
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMenuPage(),
      ),

      GoRoute(
        path: '/admin/users',
        builder: (context, state) => AdminUsersPage(),
      ),
    ],
  );
}
