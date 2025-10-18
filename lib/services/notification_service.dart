// En /lib/services/notification_service.dart

import 'api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class NotificationService {
  late final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  NotificationService() {
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final token = await _storage.read(key: 'session_token');
    if (token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null || token.isEmpty) {
        print('❌ Error en NotificationService: No se encontró token de sesión');
        throw Exception('No se encontró token de sesión');
      }
      _apiClient.setToken(token);
      final notificationsList = await _apiClient.getNotifications();
      return notificationsList;
    } catch (e) {
      print('❌ Error en NotificationService.getNotifications: $e');
      rethrow;
    }
  }

  //  Método para llamar al servicio de marcar como leída
  Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null || token.isEmpty) {
        throw Exception('No se encontró token de sesión');
      }
      _apiClient.setToken(token);

      // Llama al nuevo método del ApiClient
      await _apiClient.markNotificationAsRead(notificationId);
    } catch (e) {
      print('❌ Error en NotificationService.markAsRead: $e');
      rethrow;
    }
  }
}
