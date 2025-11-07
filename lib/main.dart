import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/chat_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // El archivo que generaste
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/home_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase aquí también
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔔 Notificación en Background: ${message.messageId}");
  print("Título: ${message.notification?.title}");
}

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 2. Asigna el handler para la app CERRADA (Background)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Handler para cuando la app está ABIERTA (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        '🔔 Notificación recibida (App Abierta): ${message.notification?.title}');

    // Aquí podrías mostrar un SnackBar o un diálogo,
    // ya que Android no muestra un popup si la app está abierta.
  });

  // 4. Handler para cuando el usuario TOCA la notificación (App en Segundo Plano)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 Notificación ABIERTA por el usuario: ${message.data}');
    // Aquí puedes navegar a la pantalla de calificaciones
    // Ejemplo: AppRouter.router.push('/ratings');
  });
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
