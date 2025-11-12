// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _initializeToken();
  }

  final _storage = const FlutterSecureStorage();
  final _tokenKey = 'session_token';
  final _userKey = 'user_data';

  late final ApiClient _apiClient;
  User? _currentUser;

  // Inicializar token al crear el servicio
  Future<void> _initializeToken() async {
    final token = await getToken();
    if (token != null) {
      _apiClient.setToken(token);
      await _loadUserData();
    }
  }

  // Guardar el token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _apiClient.setToken(token);
  }

  // Leer el token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Borrar el token (para cerrar sesión)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: 'google_user_data');
    _apiClient.clearToken();
    _currentUser = null;
  }

  // Guardar datos del usuario
  Future<void> saveUserData(User user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: json.encode(user.toJson()));
  }

  // Guardar datos adicionales de Google (como foto)
  Future<void> saveGoogleUserData({
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final googleData = {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
    print('💾 AuthService: Guardando datos de Google: $googleData');
    await _storage.write(
        key: 'google_user_data', value: json.encode(googleData));
  }

  // Obtener datos de Google guardados
  Future<Map<String, dynamic>?> getGoogleUserData() async {
    try {
      print('🔍 AuthService: Buscando datos de Google...');
      final data = await _storage.read(key: 'google_user_data');
      if (data != null) {
        final decoded = json.decode(data);
        print('✅ AuthService: Datos de Google encontrados: $decoded');
        return decoded;
      } else {
        print('⚠️ AuthService: No se encontraron datos de Google guardados');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Error obteniendo datos de Google: $e');
      return null;
    }
  }

  // Cargar datos del usuario
  Future<void> _loadUserData() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      final data = json.decode(userData);
      _currentUser = User.fromJson(data);
    }
  }
  // ... dentro de la clase AuthService

  // 👇 AÑADE ESTA NUEVA FUNCIÓN 👇
  Future<void> initializeFirebaseNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      // 1. Pedir permiso al usuario (necesario en iOS)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Obtener el Token FCM
      final fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        print("================= TOKEN FCM ==================");
        print(fcmToken);
        print("==============================================");

        // ‼️ IMPORTANTE ‼️
        // Aquí es donde llamaremos a tu API para guardar el token.
        await _apiClient.saveFcmToken(fcmToken);
      } else {
        print("Error: No se pudo obtener el token FCM.");
      }
    } catch (e) {
      print("Error al inicializar notificaciones FCM: $e");
    }
  }

  // Obtener usuario actual
  User? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Obtener usuario actual como Map (para compatibilidad)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) {
      return {
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'name': _currentUser!.name,
        'role': _currentUser!.role,
        'usuario': _currentUser!.usuario,
        'campus': _currentUser!.campus,
        'telefono': _currentUser!.telefono,
        'direccion': _currentUser!.direccion,
      };
    }
    return null;
  }

  // Login con email y password
  Future<LoginResponse> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiClient.login(email, password);
      if (response.ok && response.token != null && response.user != null) {
        await saveToken(response.token!);
        await saveUserData(response.user!);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Registro
  Future<LoginResponse> register(
      String email, String password, String name) async {
    try {
      final response = await _apiClient.register(email, password, name);
      if (response.ok && response.token != null && response.user != null) {
        await saveToken(response.token!);
        await saveUserData(response.user!);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login con Google
  Future<LoginResponse> loginWithGoogle({
    required String idToken,
    required String email,
    required String name,
    String? googleId,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.loginWithGoogle(
        idToken: idToken,
        email: email,
        name: name,
        googleId: googleId,
        avatarUrl: avatarUrl,
      );

      if (response.ok && response.token != null && response.user != null) {
        await saveToken(response.token!);
        await saveUserData(response.user!);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  } // Login con Google - SOLO Backend y PostgreSQL

  Future<Map<String, dynamic>> loginWithGoogleBackend({
    required String? idToken,
    required String? accessToken,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    print('🔄 Iniciando login con Google (SOLO BACKEND)...');
    print('📧 Email: $email');
    print('👤 Nombre: $name');
    print('🖼️ Foto URL: $photoUrl');

    try {
      // Usar idToken o accessToken
      final tokenToUse = idToken ?? accessToken;
      if (tokenToUse == null || tokenToUse.isEmpty) {
        throw Exception('No se pudo obtener token de Google');
      }

      print('🌐 Conectando a API backend...');

      final response = await _apiClient.loginWithGoogle(
        idToken: tokenToUse,
        email: email,
        name: name,
        avatarUrl: photoUrl,
      );

      if (response.ok && response.token != null) {
        // ✅ Login exitoso con BD - Guardar token JWT real
        await saveToken(response.token!);

        // Guardar datos del usuario en storage local para perfil
        if (response.user != null) {
          await saveUserData(response.user!);
        }

        // También guardar datos de Google para el perfil
        await saveGoogleUserData(
          email: email,
          name: name,
          photoUrl: photoUrl,
        );
        await initializeFirebaseNotifications();

        print('✅ Login exitoso - Usuario guardado en PostgreSQL');
        print('🔐 Token JWT: ${response.token!.substring(0, 50)}...');

        return {
          'success': true,
          'token': response.token!,
          'message': '¡Cuenta creada/actualizada en base de datos!',
          'user': response.user,
        };
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Error en la respuesta del servidor');
      }
    } catch (e) {
      print('❌ Error en login con backend: $e');
      throw Exception('Error conectando al servidor: $e');
    }
  }
  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ NUEVO: Guardar estado de "mantener sesión activa"
  Future<void> setKeepSessionActive(bool keepActive) async {
    try {
      await _storage.write(key: 'keep_session_active', value: keepActive.toString());
      print('💾 Estado de sesión guardado: $keepActive');
    } catch (e) {
      print('❌ Error guardando estado de sesión: $e');
      rethrow;
    }
  }

  // ✅ NUEVO: Obtener estado de "mantener sesión activa"
  Future<bool?> getKeepSessionActive() async {
    try {
      final value = await _storage.read(key: 'keep_session_active');
      return value != null ? value == 'true' : null;
    } catch (e) {
      print('❌ Error obteniendo estado de sesión: $e');
      return null;
    }
  }

  // Obtener el cliente API
  ApiClient get apiClient => _apiClient;
}
