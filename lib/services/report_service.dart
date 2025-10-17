//report_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'api_client.dart';

class ReportService {
  final _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  ReportService() {
    _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
    _initializeToken();
  }

  /// Inicializa el token para usarlo en las peticiones
  Future<void> _initializeToken() async {
    final token = await _storage.read(key: 'session_token');
    if (token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
    }
  }

  /// Enviar reporte de producto
  Future<Map<String, dynamic>> reportProduct(
      int productoId, String motivo) async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null) throw Exception('No se encontró token de sesión');
      // ✅ CAMBIAR: usar productId en lugar de productoId
      final data = await _apiClient.reportProduct(
        productId: productoId, // ✅ CAMBIAR nombre del parámetro
        motivo: motivo,
      );
      print('✅ Reporte enviado correctamente: $data');
      return data;
    } catch (e) {
      print('❌ Error en ReportService.reportProduct: $e');
      rethrow;
    }
  }

  /// Enviar reporte de usuario
  Future<Map<String, dynamic>> reportUser(
      int usuarioReportadoId, String motivo) async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null) throw Exception('No se encontró token de sesión');

      // ✅ CAMBIAR: usar userId en lugar de usuarioReportadoId
      final data = await _apiClient.reportUser(
        userId: usuarioReportadoId, // ✅ CAMBIAR nombre del parámetro
        motivo: motivo,
      );
      print('✅ Reporte de usuario enviado correctamente: $data');
      return data;
    } catch (e) {
      print('❌ Error en ReportService.reportUser: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getReportStates() async {
    try {
      final estados = await _apiClient.getReportStatuses();
      return estados;
    } catch (e) {
      print('❌ Error en ReportService.getReportStates: $e');
      return [];
    }
  }

  /// Obtener mis reportes (opcional)
  Future<List<dynamic>> getMyReports() async {
    try {
      final token = await _storage.read(key: 'session_token');
      if (token == null) throw Exception('No se encontró token de sesión');

      final reportes = await _apiClient.getMyReports(token);
      return reportes;
    } catch (e) {
      print('❌ Error en ReportService.getMyReports: $e');
      return [];
    }
  }
}
