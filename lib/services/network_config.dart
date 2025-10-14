import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NetworkConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // En Web siempre apuntas al backend accesible por navegador
      return 'http://localhost:3001/api';
    } else if (Platform.isAndroid) {
      // Para emulador Android
      return 'http://10.0.2.2:3001/api';
    } else if (Platform.isIOS) {
      // Para simulador iOS
      return 'http://localhost:3001/api';
    } else {
      // Desktop u otros
      return 'http://localhost:3001/api';
    }
  }

  static String get websocketUrl {
    if (kIsWeb) {
      return 'http://localhost:3001';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      return 'http://localhost:3001';
    } else {
      return 'http://localhost:3001';
    }
  }
}
