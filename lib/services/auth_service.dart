  // lib/services/auth_service.dart
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  class AuthService {
    final _storage = const FlutterSecureStorage();
    final _tokenKey = 'session_token';

    // Guardar el token
    Future<void> saveToken(String token) async {
      await _storage.write(key: _tokenKey, value: token);
    }

    // Leer el token
    Future<String?> getToken() async {
      return await _storage.read(key: _tokenKey);
    }

    // Borrar el token (para cerrar sesión)
    Future<void> deleteToken() async {
      await _storage.delete(key: _tokenKey);
    }
  }
