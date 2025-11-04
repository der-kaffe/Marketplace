import 'dart:async';
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
  final StreamController<Map<String, dynamic>> _groupMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters para los streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get groupMessageStream =>
      _groupMessageController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Método para verificar el estado de la conexión
  void debugConnectionStatus() {
  }

  // Método para forzar reconexión
  Future<void> forceReconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  Future<void> connect() async {
    try {

      final token = await _storage.read(key: 'session_token');

      if (token == null) {
        return;
      }


      // Desconectar socket anterior si existe
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
      }

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

      _setupEventListeners();


      // Forzar conexión manual si autoConnect no funciona
      _socket!.connect();
    } catch (e) {
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _connectionController.add(true);
    });

    _socket?.onDisconnect((reason) {
      _connectionController.add(false);
    });

    _socket?.onConnectError((error) {
      _connectionController.add(false);
    });

    _socket?.onReconnect((attemptNumber) {
      _connectionController.add(true);
    });

    _socket?.onReconnectError((error) {
      _connectionController.add(false);
    });

    // Escuchar nuevos mensajes
    _socket?.on('new_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar confirmación de mensaje enviado
    _socket?.on('message_sent', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar errores de mensaje
    _socket?.on('message_error', (data) {
    });

    // Escuchar indicadores de escritura
    _socket?.on('user_typing', (data) {
      _typingController.add(Map<String, dynamic>.from(data));
    });

    // Escuchar usuarios online/offline
    _socket?.on('user_online', (data) {
    });

    _socket?.on('user_offline', (data) {
    });

    // Mensajes de la comunidad
    _socket?.on('group_new_message', (data) {
      _groupMessageController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('group_message_sent', (data) {
      _groupMessageController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('group_message_error', (data) {
      // Podríamos emitir a otro stream de errores si fuera necesario
    });
  }

  void sendMessage({
    required int destinatarioId,
    required String contenido,
    String tipo = 'texto',
  }) {

    if (_socket?.connected != true) {
      connect(); // Intentar reconectar
      return;
    }

    final messageData = {
      'destinatarioId': destinatarioId,
      'contenido': contenido,
      'tipo': tipo,
    };

    _socket?.emit('send_message', messageData);
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

  void sendGroupMessage({
    required String contenido,
    String tipo = 'texto',
  }) {
    if (_socket?.connected != true) {
      connect();
      return;
    }

    final messageData = {
      'contenido': contenido,
      'tipo': tipo,
    };

    _socket?.emit('send_group_message', messageData);
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
    _groupMessageController.close();
  }
}
