import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'websocket_service.dart';
import 'network_config.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final WebSocketService _wsService = WebSocketService();
  final String baseUrl = NetworkConfig.baseUrl;

  // Getters para streams
  Stream<Map<String, dynamic>> get messageStream => _wsService.messageStream;
  Stream<Map<String, dynamic>> get typingStream => _wsService.typingStream;
  Stream<bool> get connectionStream => _wsService.connectionStream;

  bool get isConnected => _wsService.isConnected;

  Future<void> initialize() async {
    await _wsService.connect();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'session_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener conversaciones del usuario
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      print('🔄 ChatService: Obteniendo conversaciones...');
      final headers = await _getAuthHeaders();
      print('🔑 Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversaciones'),
        headers: headers,
      );

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final conversations = List<Map<String, dynamic>>.from(data['conversaciones']);
          print('✅ Conversaciones obtenidas: ${conversations.length}');
          return conversations;
        } else {
          print('❌ Error en respuesta: ${data['message']}');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo conversaciones: $e');
      return [];
    }
  }

  // Obtener mensajes de una conversación específica
  Future<List<Map<String, dynamic>>> getMessages(int usuarioId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversacion/$usuarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          return List<Map<String, dynamic>>.from(data['mensajes']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo mensajes: $e');
      return [];
    }
  }

  // Enviar mensaje (usando WebSocket para tiempo real)
  void sendMessage({
    required int destinatarioId,
    required String contenido,
    String tipo = 'texto',
  }) {
    _wsService.sendMessage(
      destinatarioId: destinatarioId,
      contenido: contenido,
      tipo: tipo,
    );
  }

  // Enviar mensaje usando API REST (fallback)
  Future<bool> sendMessageRest({
    required int destinatarioId,
    required String contenido,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: headers,
        body: json.encode({
          'destinatarioId': destinatarioId,
          'contenido': contenido,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enviando mensaje REST: $e');
      return false;
    }
  }

  // Indicadores de escritura
  void startTyping(int destinatarioId) {
    _wsService.startTyping(destinatarioId);
  }

  void stopTyping(int destinatarioId) {
    _wsService.stopTyping(destinatarioId);
  }

  // Formatear mensaje para la UI
  Map<String, dynamic> formatMessage(Map<String, dynamic> message, int currentUserId) {
    final isMe = message['remitenteId'] == currentUserId;
    final remitente = message['remitente'] ?? {};
    final destinatario = message['destinatario'] ?? {};
    
    return {
      'id': message['id'],
      'text': message['contenido'],
      'isMe': isMe,
      'timestamp': message['fechaEnvio'],
      'tipo': message['tipo'] ?? 'texto',
      'remitente': {
        'id': remitente['id'],
        'nombre': remitente['nombre'],
        'usuario': remitente['usuario'],
      },
      'destinatario': {
        'id': destinatario['id'],
        'nombre': destinatario['nombre'],
        'usuario': destinatario['usuario'],
      },
    };
  }

  // Formatear conversación para la UI
  Map<String, dynamic> formatConversation(Map<String, dynamic> conversation, int currentUserId) {
    final ultimoMensaje = conversation['ultimoMensaje'] ?? {};
    final usuario = conversation['usuario'] ?? {};
    final isMe = ultimoMensaje['remitenteId'] == currentUserId;
    
    return {
      'id': usuario['id'],
      'name': usuario['nombre'],
      'username': usuario['usuario'],
      'lastMessage': ultimoMensaje['contenido'] ?? '',
      'time': _formatTime(ultimoMensaje['fechaEnvio']),
      'unread': 0, // TODO: Implementar contador de mensajes no leídos
      'avatar': 'https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg',
      'isMe': isMe,
    };
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return '';
    }
  }

  void dispose() {
    _wsService.dispose();
  }
}
