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
    await _storage.delete(key: 'google_user_data');
    _apiClient.clearToken();
    _currentUser = null;
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
    await _storage.write(key: 'google_user_data', value: json.encode(googleData));
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
  // Login con Google - Estrategia Híbrida
  Future<Map<String, dynamic>> loginWithGoogleHybrid({
    required String? idToken,
    required String? accessToken,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    print('🔄 Iniciando login híbrido con Google...');
    
    // 1️⃣ PRIMERO: Intentar guardar en BD (producción)
    if (idToken != null && idToken.isNotEmpty) {
      try {
        print('🌐 Intentando login con API...');
        
        final response = await _apiClient.loginWithGoogle(
          idToken: idToken,
          email: email,
          name: name,
          avatarUrl: photoUrl,
        );
        
        if (response.ok && response.token != null) {
          // ✅ Login exitoso con BD
          await saveToken(response.token!);
          
          if (response.user != null) {
            await saveUserData(response.user!);
          }
          
          // También guardar datos de Google para el perfil
          await saveGoogleUserData(
            email: email,
            name: name,
            photoUrl: photoUrl,
          );
          
          print('✅ Login con BD exitoso - Token: ${response.token!}');
          return {
            'success': true,
            'mode': 'database',
            'token': response.token!,
            'message': '¡Login exitoso con base de datos!',
          };
        }
      } catch (apiError) {
        print('⚠️ Error en API: $apiError');
      }
    }
    
    // 2️⃣ FALLBACK: Si falla la API, usar modo local (desarrollo)
    print('🔧 Usando modo local (desarrollo)');
    
    final mockToken = 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveToken(mockToken);
    
    // Guardar datos localmente como respaldo
    await saveGoogleUserData(
      email: email,
      name: name,
      photoUrl: photoUrl,
    );
    
    print('✅ Login local exitoso con token: $mockToken');
    return {
      'success': true,
      'mode': 'local',
      'token': mockToken,
      'message': '¡Login exitoso! (Modo desarrollo)',
    };
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Obtener el cliente API
  ApiClient get apiClient => _apiClient;
}
