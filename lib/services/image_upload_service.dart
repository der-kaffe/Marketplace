import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_config.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = NetworkConfig.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'session_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Subir imagen y obtener URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      print('📤 Subiendo imagen: ${imageFile.path}');
      
      final token = await _storage.read(key: 'session_token');
      if (token == null) {
        print('❌ No hay token de autenticación');
        return null;
      }

      // Usar la URL correcta para subida
      String uploadUrl = baseUrl.replaceAll('/api', '') + '/api/chat/upload-image';
      print('🌐 URL de subida: $uploadUrl');

      // Crear multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );

      // Agregar headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      print('📤 Enviando request de subida...');
      // Enviar request
      var response = await request.send();
      
      print('📡 Respuesta recibida: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('📄 Respuesta: $responseData');
        var jsonData = json.decode(responseData);
        
        if (jsonData['ok']) {
          final imageUrl = jsonData['imageUrl'];
          print('✅ Imagen subida exitosamente: $imageUrl');
          return imageUrl;
        } else {
          print('❌ Error en respuesta: ${jsonData['message']}');
        }
      } else {
        var errorBody = await response.stream.bytesToString();
        print('❌ Error HTTP: ${response.statusCode} - $errorBody');
      }
      
      return null;
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      return null;
    }
  }

  // Convertir imagen a base64 (fallback)
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('❌ Error convirtiendo imagen a base64: $e');
      return null;
    }
  }
}
