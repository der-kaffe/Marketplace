import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación horizontal solo en móviles
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Configuramos GoogleSignIn solo para Web
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "923310808660-u1lvndctmelhjggu81qem3la55monf1l.apps.googleusercontent.com"
        : null,
  );

  // Inicializar servicios
  await ChatService().initialize();

  runApp(MyApp(googleSignIn: googleSignIn));
}

class MyApp extends StatelessWidget {
  final GoogleSignIn googleSignIn;

  const MyApp({super.key, required this.googleSignIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MicroMarket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
    );
  }
}
