import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MicroMarket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Aplicamos el tema personalizado
      darkTheme: AppTheme.darkTheme, // Tema oscuro opcional
      themeMode: ThemeMode.light, // Por defecto usamos el tema claro
      
      // Usamos el router definido en app_router.dart
      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
    );
  }
}
