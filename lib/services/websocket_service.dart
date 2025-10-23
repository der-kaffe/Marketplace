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

  // Método para verificar el estado de la conexión
  void debugConnectionStatus() {
    print('🔍 DEBUG CONEXIÓN WEBSOCKET:');
    print('   - Socket existe: ${_socket != null}');
    print('   - Socket conectado: ${_socket?.connected}');
    print('   - URL configurada: ${NetworkConfig.websocketUrl}');
    print('   - Estado isConnected: $isConnected');
  }

  // Método para forzar reconexión
  Future<void> forceReconnect() async {
    print('🔄 Forzando reconexión WebSocket...');
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  Future<void> connect() async {
    try {
      print('🔌 Iniciando conexión WebSocket...');

      final token = await _storage.read(key: 'session_token');
      print('🔑 Token encontrado: ${token != null ? 'Sí' : 'No'}');

      if (token == null) {
        print('❌ No se encontró token de autenticación (session_token)');
        return;
      }

      print('🌐 URL WebSocket: ${NetworkConfig.websocketUrl}');
      print('🔑 Token (primeros 20 chars): ${token.substring(0, 20)}...');

      // Desconectar socket anterior si existe
      if (_socket != null) {
        print('🔌 Desconectando socket anterior...');
        _socket!.disconnect();
        _socket!.dispose();
      }

      print('🔌 Creando nuevo socket...');
      _socket = IO.io(
        NetworkConfig.websocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1500)
            .setReconnectionDelayMax(30000)
            .setAuth({'token': token})
            .setTimeout(10000) // 10 segundos de timeout
            .build(),
      );

      print('🔌 Configurando event listeners...');
      _setupEventListeners();

      print('✅ Configuración WebSocket completada');

      // Forzar conexión manual si autoConnect no funciona
      print('🔌 Intentando conexión manual...');
      _socket!.connect();
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      print('✅ WebSocket CONECTADO exitosamente');
      _connectionController.add(true);
    });

    _socket?.onDisconnect((reason) {
      print('🔌 WebSocket DESCONECTADO. Razón: $reason');
      _connectionController.add(false);
    });

    _socket?.onConnectError((error) {
      print('❌ ERROR de conexión WebSocket: $error');
      print('❌ Tipo de error: ${error.runtimeType}');
      _connectionController.add(false);
    });

    _socket?.onReconnect((attemptNumber) {
      print('🔄 WebSocket RECONECTADO (intento $attemptNumber)');
      _connectionController.add(true);
    });

    _socket?.onReconnectError((error) {
      print('❌ ERROR de reconexión WebSocket: $error');
      _connectionController.add(false);
    });

    // Escuchar nuevos mensajes
    _socket?.on('new_message', (data) {
      print('📨 Nuevo mensaje recibido: $data');
      print('📨 Tipo de datos: ${data.runtimeType}');
      print('📨 Contenido del mensaje: ${data['contenido']}');
      print('📨 Remitente: ${data['remitenteId']}');
      print('📨 Destinatario: ${data['destinatarioId']}');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar confirmación de mensaje enviado
    _socket?.on('message_sent', (data) {
      print('✅ Mensaje enviado confirmado: $data');
      print('✅ Tipo de datos: ${data.runtimeType}');
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
    print('📤 Intentando enviar mensaje...');
    print('🔌 WebSocket conectado: ${_socket?.connected}');
    print('👤 Destinatario ID: $destinatarioId');
    print('📝 Contenido: "$contenido"');
    print('🏷️ Tipo: $tipo');

    if (_socket?.connected != true) {
      print('❌ WebSocket no conectado. Estado: ${_socket?.connected}');
      print('🔧 Intentando reconectar...');
      connect(); // Intentar reconectar
      return;
    }

    final messageData = {
      'destinatarioId': destinatarioId,
      'contenido': contenido,
      'tipo': tipo,
    };

    print('📤 Emitiendo evento send_message con datos: $messageData');
    _socket?.emit('send_message', messageData);
    print('✅ Evento send_message emitido');
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
