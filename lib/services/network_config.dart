import 'dart:io';

class NetworkConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Para emulador Android
      return 'http://10.0.2.2:3001/api';
    } else if (Platform.isIOS) {
      // Para simulador iOS
      return 'http://localhost:3001/api';
    } else {
      // Para web y desktop
      return 'http://localhost:3001/api';
    }
  }

  static String get websocketUrl {
    if (Platform.isAndroid) {
      // Para emulador Android
      return 'http://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      // Para simulador iOS
      return 'http://localhost:3001';
    } else {
      // Para web y desktop
      return 'http://localhost:3001';
    }
  }
}
