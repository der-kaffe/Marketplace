// En rating_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'api_client.dart';

class RatingService {
  final _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  RatingService() {
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final token = await _storage.read(key: 'session_token');
    if (token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
    }
  }

  /// Califica a un vendedor con una puntuación y comentario opcional
  Future<Map<String, dynamic>> rateSeller({
    required int sellerId,
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      print('🔍 RatingService.rateSeller - Parámetros recibidos:');
      print('   sellerId: $sellerId');
      print('   puntuacion: $puntuacion');
      print('   comentario: $comentario');

      final token = await _storage.read(key: 'session_token');
      print('   token encontrado: ${token != null}');

      if (token == null) throw Exception('No se encontró token de sesión');

      // Enviar la calificación al backend
      final data = await _apiClient.rateSeller(
        sellerId: sellerId,
        puntuacion: puntuacion,
        comentario: comentario,
      );

      print('✅ Calificación enviada correctamente: $data');
      return data;
    } catch (e) {
      print('❌ Error en RatingService.rateSeller: $e');
      print('   Tipo de error: ${e.runtimeType}');

      // Propagar la excepción tal cual para que el UI pueda manejarla
      rethrow; // ESTO ES CRUCIAL
    }
  }

  /// Obtiene todas las calificaciones de un vendedor
  Future<List<dynamic>> getSellerRatings(int sellerId) async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null) throw Exception('No se encontró token de sesión');

      final data = await _apiClient.getSellerRatings(sellerId);

      print('📦 Calificaciones del vendedor $sellerId: $data');

      // la API devuelve `{ success, data: [...] }`
      final ratings = (data['data'] ?? []) as List<dynamic>;
      return ratings;
    } catch (e) {
      print('❌ Error en RatingService.getSellerRatings: $e');
      return [];
    }
  }
}
