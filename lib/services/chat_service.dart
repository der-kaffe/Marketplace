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
  Stream<Map<String, dynamic>> get groupMessageStream =>
      _wsService.groupMessageStream;

  bool get isConnected => _wsService.isConnected;

  Future<void> initialize() async {
    try {

      // Primero verificar conectividad HTTP
      await _testHttpConnectivity();

      await _wsService.connect();

      // Esperar un poco para que la conexión se establezca
      await Future.delayed(const Duration(milliseconds: 3000));

      // Debug del estado de conexión
      _wsService.debugConnectionStatus();

      if (_wsService.isConnected) {
      } else {

        // Intentar reconectar una vez más
        await _wsService.connect();
        await Future.delayed(const Duration(milliseconds: 2000));

        if (_wsService.isConnected) {
        } else {
          _enablePollingMode();
        }
      }
    } catch (e) {
      _enablePollingMode();
    }
  }

  // Habilitar modo polling como fallback
  void _enablePollingMode() {
    // TODO: Implementar polling de mensajes cada 2-3 segundos
    // Por ahora, los mensajes se enviarán via REST API
  }

  Future<void> _testHttpConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/api/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
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
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversaciones'),
        headers: headers,
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final conversations =
              List<Map<String, dynamic>>.from(data['conversaciones']);
          return conversations;
        } else {
        }
      } else {
      }
      return [];
    } catch (e) {
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
      return [];
    }
  }

  // Comunidad UCT: obtener historial
  Future<List<Map<String, dynamic>>> getCommunityMessages({int limit = 50}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/community/messages?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          return List<Map<String, dynamic>>.from(data['mensajes']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Enviar mensaje (usando WebSocket para tiempo real con fallback a REST)
  Future<void> sendMessage({
    required int destinatarioId,
    required String contenido,
    String tipo = 'texto',
  }) async {

    // Verificar si WebSocket está conectado
    if (!_wsService.isConnected) {
      await initialize();

      // Intentar nuevamente después de reconectar
      if (!_wsService.isConnected) {
        final success = await sendMessageRest(
          destinatarioId: destinatarioId,
          contenido: contenido,
        );
        if (success) {
        } else {
          throw Exception('Error enviando mensaje');
        }
        return;
      }
    }
    // Usar WebSocket si está conectado
    _wsService.sendMessage(
      destinatarioId: destinatarioId,
      contenido: contenido,
      tipo: tipo,
    );
  }

//   Marcar mensajes como leídos
  Future<void> markMessagesAsRead(int usuarioId) async {
    try {
      // 1. Obtiene los headers de autenticación (como ya haces)
      final headers = await _getAuthHeaders();

      // 2. Define la URL del nuevo endpoint
      final uri = Uri.parse('$baseUrl/chat/conversacion/$usuarioId/mark-read');

      // 3. Llama a la API usando http.post
      final response = await http.post(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
        } else {
          throw Exception('Error en respuesta de mark-read');
        }
      } else {
        throw Exception('Error al marcar mensajes como leídos');
      }
    } catch (e) {
      rethrow; // Propaga el error para que la UI lo pueda manejar
    }
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

  // Comunidad UCT: enviar mensaje
  Future<void> sendGroupMessage({
    required String contenido,
    String tipo = 'texto',
  }) async {
    if (!_wsService.isConnected) {
      await initialize();
      if (!_wsService.isConnected) {
        throw Exception('Sin conexión para enviar a la comunidad');
      }
    }
    _wsService.sendGroupMessage(contenido: contenido, tipo: tipo);
  }

  // Formatear mensaje para la UI
  Map<String, dynamic> formatMessage(
      Map<String, dynamic> message, int currentUserId) {
    final isMe = message['remitenteId'] == currentUserId;
    final remitente = message['remitente'] ?? {};
    final destinatario = message['destinatario'] ?? {};

    return {
      'id': message['id'],
      'text': message['contenido'],
      'isMe': isMe,
      'timestamp': message['fechaEnvio'],
      'tipo': message['tipo'] ?? 'texto',
      'remitenteId': message['remitenteId'],
      'destinatarioId': message['destinatarioId'],
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
  Map<String, dynamic> formatConversation(
      Map<String, dynamic> conversation, int currentUserId) {
    final ultimoMensaje = conversation['ultimoMensaje'] ?? {};
    final usuario = conversation['usuario'] ?? {};
    final isMe = ultimoMensaje['remitenteId'] == currentUserId;


    // Formatear el último mensaje
    String lastMessageText = ultimoMensaje['contenido'] ?? '';
    String tipo = ultimoMensaje['tipo'] ?? 'texto';

    // Agregar prefijo según el tipo de mensaje
    String formattedMessage = lastMessageText;
    if (tipo == 'imagen') {
      formattedMessage = '📷 Imagen';
    } else if (tipo == 'audio') {
      formattedMessage = '🎵 Audio';
    } else if (tipo == 'video') {
      formattedMessage = '🎥 Video';
    }

    // Agregar prefijo si es mensaje propio
    if (isMe && formattedMessage.isNotEmpty) {
      formattedMessage = 'Tú: $formattedMessage';
    }

    return {
      'id': usuario['id'],
      'name': usuario['nombre'],
      'username': usuario['usuario'],
      'lastMessage': formattedMessage,
      'time': _formatTime(ultimoMensaje['fechaEnvio']),
      'unread': conversation['unreadCount'] ?? 0,
      'avatar':
          'https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg',
      'isMe': isMe,
    };
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        // Si es más de una semana, mostrar la fecha
        return '${date.day}/${date.month}';
      } else if (difference.inDays > 0) {
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
