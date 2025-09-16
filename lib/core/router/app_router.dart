// app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importa todas tus pantallas
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/conversations_page.dart';
import '../../screens/home_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/new_post_screen.dart';
import '../../screens/startup.dart';
import '../../screens/notifications_screen.dart';

// Admin
import '../../screens/admin_menu_page.dart';
import '../../screens/admin_users_page.dart';
import '../../screens/admin_reports_page.dart';
import '../../screens/admin_report_detail_page.dart';

// Services
import '../../services/auth_service.dart';

class AppRouter {
  // Instancia del servicio de autenticación para usar en el redirect
  static final _authService = AuthService();

  static final GoRouter router = GoRouter(
    initialLocation: '/startup',

    // La lógica de redirección protege las rutas de la aplicación
    redirect: (BuildContext context, GoRouterState state) async {
      // 1. Verifica si el usuario tiene un token de sesión guardado
      final token = await _authService.getToken();
      final bool isLoggedIn = token != null;

      // 2. Define cuáles son las rutas públicas (accesibles sin login)
      final isPublicRoute = state.matchedLocation == '/startup' ||
          state.matchedLocation == '/login';

      // 3. Aplica las reglas de redirección
      // CASO A: El usuario NO está autenticado y quiere acceder a una ruta protegida
      if (!isLoggedIn && !isPublicRoute) {
        // Redirige al usuario a la pantalla de login
        return '/login';
      }

      // CASO B: El usuario SÍ está autenticado y trata de acceder a una ruta pública
      if (isLoggedIn && isPublicRoute) {
        // Redirige al usuario a la pantalla principal de la app
        return '/home';
      }

      // En cualquier otro caso (usuario logueado en ruta protegida, o no logueado en ruta pública),
      // no se necesita redirección.
      return null;
    },

    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Rutas principales de la aplicación dentro de un ShellRoute para la barra de navegación
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
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
          // Ruta para crear una nueva publicación
          GoRoute(
            path: '/new_post',
            builder: (context, state) => const NewPostScreen(),
          ),
        // Ruta de notificaciones
        GoRoute(
              path: '/home/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
        ],
      ),

      // Rutas del panel de Administrador (ahora protegidas por el redirect)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMenuPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsPage(),
      ),
      GoRoute(
        path: '/admin/reports/:id',
        builder: (context, state) {
          final reportId = int.tryParse(state.pathParameters['id'] ?? '');
          // Es buena práctica manejar el caso donde el ID no es un número válido
          if (reportId == null) {
            // Puedes redirigir a una página de error o a la lista de reportes
            return const AdminReportsPage();
          }
          return ReportDetailPage(reportId: reportId);
        },
      ),
    ],
    // Opcional: Manejo de errores para rutas no encontradas
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.error}'),
      ),
    ),
  );
}
