  // lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _tokenKey = 'session_token';
  final _userKey = 'user_data';
  final _authTypeKey = 'auth_type'; // google, email, guest, admin
  
  late final ApiClient _apiClient;
  late final GoogleSignIn _googleSignIn;
  User? _currentUser;
  String? _authType;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
    );
    
    await _initializeToken();
    _initialized = true;
  }
  // Inicializar token al crear el servicio
  Future<void> _initializeToken() async {
    final token = await getToken();
    if (token != null) {
      _apiClient.setToken(token);
      await _loadUserData();
      _authType = await _storage.read(key: _authTypeKey);
    }
  }

  // Guardar el token y tipo de autenticación
  Future<void> saveToken(String token, {String authType = 'email'}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _authTypeKey, value: authType);
    _apiClient.setToken(token);
    _authType = authType;
  }

  // Leer el token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Obtener tipo de autenticación
  String? get authType => _authType;
  bool get isGoogleAuth => _authType == 'google';
  bool get isGuestMode => _authType == 'guest';
  bool get isAdminMode => _authType == 'admin';

  // Borrar el token (para cerrar sesión)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _authTypeKey);
    _apiClient.clearToken();
    _currentUser = null;
    _authType = null;
  }

  // Cerrar sesión completa
  Future<void> logout() async {
    try {
      // Si es Google Auth, cerrar sesión en Google también
      if (isGoogleAuth) {
        await _googleSignIn.signOut();
      }
      
      // Borrar datos locales
      await deleteToken();
    } catch (e) {
      // Aunque falle Google, borramos datos locales
      await deleteToken();
      rethrow;
    }
  }

  // Guardar datos del usuario
  Future<void> saveUserData(User user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: json.encode({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'role': user.role,
    }));
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
        await saveToken(response.token!, authType: 'email');
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
        await saveToken(response.token!, authType: 'email');
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
        await saveToken(response.token!, authType: 'google');
        await saveUserData(response.user!);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login como invitado
  Future<void> loginAsGuest() async {
    await saveToken('guest_user_token', authType: 'guest');
    // Crear usuario guest temporal
    _currentUser = User(
      id: 0,
      email: 'guest@marketplace.com',
      name: 'Usuario Invitado',
      role: 'guest',
    );
    await saveUserData(_currentUser!);
  }

  // Login como admin (para testing)
  Future<void> loginAsAdmin() async {
    await saveToken('admin_user_token', authType: 'admin');
    // Crear usuario admin temporal
    _currentUser = User(
      id: -1,
      email: 'admin@marketplace.com',
      name: 'Administrador',
      role: 'admin',
    );
    await saveUserData(_currentUser!);
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Obtener el cliente API
  ApiClient get apiClient => _apiClient;
}
