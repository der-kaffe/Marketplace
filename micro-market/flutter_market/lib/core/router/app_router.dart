// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/conversations_page.dart';
import '../../screens/home_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/startup_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/startup',
    routes: [
      GoRoute(path: '/startup', builder: (context, state) => const StartupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
          GoRoute(
            path: '/home/messages',
            builder: (context, state) => ConversationsPage(),
          ),
          GoRoute(
            path: '/home/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/home/chat/:userName',
            pageBuilder: (context, state) {
              final userName = state.pathParameters['userName']!;
              final avatar = state.uri.queryParameters['avatar'] ?? '';

              // CustomTransitionPage evita que se vea la página anterior
              return CustomTransitionPage(
                key: state.pageKey,
                child: ChatPage(userName: userName, avatar: avatar),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      final tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      final offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
              );
            },
          ),
        ],
      ),
    ],
  );
}
