  // lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_client.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _tokenKey = 'session_token';
  final _userKey = 'user_data';
  
  late final ApiClient _apiClient;
  User? _currentUser;

  AuthService() {
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _initializeToken();
  }

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
    _apiClient.clearToken();
    _currentUser = null;
  }
  // Guardar datos del usuario
  Future<void> saveUserData(User user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: json.encode(user.toJson()));
  }

  // Cargar datos del usuario
  Future<void> _loadUserData() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      final data = json.decode(userData);
      _currentUser = User.fromJson(data);
    }
  }

  // Obtener usuario actual
  User? get currentUser => _currentUser;

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
  Future<LoginResponse> register(String email, String password, String name) async {
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
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Obtener el cliente API
  ApiClient get apiClient => _apiClient;
}
