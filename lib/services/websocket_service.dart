import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Streams para notificar cambios
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // Getters para los streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        print('❌ No se encontró token de autenticación');
        return;
      }

      _socket = IO.io(
        NetworkConfig.websocketUrl, 
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _setupEventListeners();
      
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      print('🔌 WebSocket conectado');
      _connectionController.add(true);
    });

    _socket?.onDisconnect((_) {
      print('🔌 WebSocket desconectado');
      _connectionController.add(false);
    });

    _socket?.onConnectError((error) {
      print('❌ Error de conexión WebSocket: $error');
      _connectionController.add(false);
    });

    // Escuchar nuevos mensajes
    _socket?.on('new_message', (data) {
      print('📨 Nuevo mensaje recibido: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar confirmación de mensaje enviado
    _socket?.on('message_sent', (data) {
      print('✅ Mensaje enviado confirmado: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar errores de mensaje
    _socket?.on('message_error', (data) {
      print('❌ Error enviando mensaje: $data');
    });

    // Escuchar indicadores de escritura
    _socket?.on('user_typing', (data) {
      print('⌨️ Usuario escribiendo: $data');
      _typingController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar usuarios online/offline
    _socket?.on('user_online', (data) {
      print('🟢 Usuario online: $data');
    });

    _socket?.on('user_offline', (data) {
      print('🔴 Usuario offline: $data');
    });
  }

  void sendMessage({
    required int destinatarioId,
    required String contenido,
    String tipo = 'texto',
  }) {
    if (_socket?.connected != true) {
      print('❌ WebSocket no conectado');
      return;
    }

    _socket?.emit('send_message', {
      'destinatarioId': destinatarioId,
      'contenido': contenido,
      'tipo': tipo,
    });
  }

  void startTyping(int destinatarioId) {
    if (_socket?.connected != true) return;
    
    _socket?.emit('typing_start', {
      'destinatarioId': destinatarioId,
    });
  }

  void stopTyping(int destinatarioId) {
    if (_socket?.connected != true) return;
    
    _socket?.emit('typing_stop', {
      'destinatarioId': destinatarioId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
  }
}

