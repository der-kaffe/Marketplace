// app.router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/conversations_page.dart';
import '../../screens/home_screen.dart'; 

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => HomeScreen(), 
          ),
          GoRoute(
            path: '/home/messages',
            builder: (context, state) => ConversationsPage(),
          ),
          GoRoute(
            path: '/home/chat/:userName',
            builder: (context, state) {
              final userName = state.pathParameters['userName']!;
              final avatar = state.uri.queryParameters['avatar'] ?? '';
              return ChatPage(userName: userName, avatar: avatar);
            },
          ),
          
        ],
      ),
    ],
  );
}