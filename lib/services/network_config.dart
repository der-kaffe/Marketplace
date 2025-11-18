import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NetworkConfig {
  // 🚀 La IP pública de tu servidor
  static const String _productionIp = 'http://186.64.113.170:3001';

  static String get baseUrl {
    // Para una APK pública, todas las plataformas apuntan a la misma IP
    return '$_productionIp/api';
  }

  static String get websocketUrl {
    // El websocket se conecta al servidor raíz (sin /api)
    return _productionIp;
  }
}
