import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';

class ChatView extends StatefulWidget {
  final int destinatarioId;
  final String destinatarioNombre;
  
  const ChatView({
    super.key, 
    required this.destinatarioId,
    required this.destinatarioNombre,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<Map<String, dynamic>> messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  
  int? _currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Cargar usuario actual primero
    await _loadCurrentUser();
    
    // Inicializar el servicio de chat y conectar WebSocket
    await _chatService.initialize();
    
    // Esperar un momento para que la conexión WebSocket se establezca
    await Future.delayed(const Duration(milliseconds: 500));
    
    _setupWebSocketListeners();
    
    // Cargar mensajes después de tener el currentUserId
    await _loadMessages();
    
    // Verificar conexión WebSocket
    if (_chatService.isConnected) {
      print('✅ WebSocket conectado correctamente');
    } else {
      print('⚠️ WebSocket no conectado, intentando reconectar...');
      await _chatService.initialize();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  Future<void> _loadMessages() async {
    // Asegurar que tenemos el currentUserId antes de cargar mensajes
    if (_currentUserId == null) {
      await _loadCurrentUser();
    }
    
    final messagesList = await _chatService.getMessages(widget.destinatarioId);
    
    setState(() {
      messages.clear();
      messages.addAll(messagesList.map((msg) => 
        _chatService.formatMessage(msg, _currentUserId ?? 0)
      ));
    });
    
    _scrollToBottom();
  }

  void _setupWebSocketListeners() {
    _messageSubscription = _chatService.messageStream.listen((message) {
      if (!mounted) return; // Verificar que el widget aún esté montado
      
      print('🔍 Mensaje recibido en ChatView: $message');
      print('👤 Usuario actual: $_currentUserId');
      print('🎯 Destinatario: ${widget.destinatarioId}');
      
      // Solo agregar mensajes de esta conversación específica
      final remitenteId = message['remitenteId'];
      final destinatarioId = message['destinatarioId'];
      
      final isFromThisConversation = 
          (remitenteId == _currentUserId && destinatarioId == widget.destinatarioId) ||
          (remitenteId == widget.destinatarioId && destinatarioId == _currentUserId);
      
      print('✅ Es de esta conversación: $isFromThisConversation');
      
      if (isFromThisConversation) {
        // Verificar si el mensaje ya existe para evitar duplicados
        final messageId = message['id'];
        final exists = messages.any((msg) => msg['id'] == messageId);
        
        print('📝 Mensaje ya existe: $exists');
        
        if (!exists) {
          final formattedMessage = _chatService.formatMessage(message, _currentUserId ?? 0);
          print('➕ Agregando mensaje formateado: $formattedMessage');
          
          setState(() {
            // Buscar y remover mensaje temporal si existe
            final tempIndex = messages.indexWhere((msg) => 
              msg['temp'] == true && 
              msg['text'] == formattedMessage['text'] &&
              msg['remitenteId'] == formattedMessage['remitenteId']
            );
            
            if (tempIndex != -1) {
              // Reemplazar mensaje temporal con el real
              messages[tempIndex] = formattedMessage;
              print('🔄 Reemplazando mensaje temporal con real');
            } else {
              // Agregar nuevo mensaje
              messages.add(formattedMessage);
            }
          });
          _scrollToBottom();
        }
      }
    });

    _typingSubscription = _chatService.typingStream.listen((data) {
      if (!mounted) return; // Verificar que el widget aún esté montado
      
      if (data['userId'] == widget.destinatarioId) {
        setState(() {
          _isTyping = data['isTyping'] ?? false;
        });
      }
    });

    // Escuchar cambios en el estado de conexión
    _connectionSubscription = _chatService.connectionStream.listen((isConnected) {
      if (!mounted) return;
      
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conexión perdida. Intentando reconectar...'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conexión restablecida'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Limpiar el campo de texto inmediatamente
    _controller.clear();
    _stopTyping();
    
    // Crear un mensaje temporal para mostrar inmediatamente
    final tempMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'text': text,
      'isMe': true,
      'timestamp': DateTime.now().toIso8601String(),
      'tipo': 'texto',
      'remitenteId': _currentUserId,
      'destinatarioId': widget.destinatarioId,
      'temp': true, // Marcar como temporal
    };
    
    // Agregar mensaje temporal a la lista
    setState(() {
      messages.add(tempMessage);
    });
    _scrollToBottom();
    
    try {
      await _chatService.sendMessage(
        destinatarioId: widget.destinatarioId,
        contenido: text,
      );
      
      // El WebSocket reemplazará el mensaje temporal con el real
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      
      // Remover mensaje temporal si falla el envío
      setState(() {
        messages.removeWhere((msg) => msg['id'] == tempMessage['id']);
      });
      
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (img == null) return;
      
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo imagen...'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Subir imagen al servidor
      final imageFile = File(img.path);
      final imageUrl = await _imageUploadService.uploadImage(imageFile);
      
      if (imageUrl != null) {
        // Enviar mensaje con URL de la imagen
        await _chatService.sendMessage(
          destinatarioId: widget.destinatarioId,
          contenido: imageUrl,
          tipo: 'imagen',
        );
        
        // No recargar mensajes manualmente - el WebSocket se encarga
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen enviada'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Fallback: usar base64
        print('⚠️ Fallback a base64 para imagen');
        final base64Image = await _imageUploadService.imageToBase64(imageFile);
        if (base64Image != null) {
          await _chatService.sendMessage(
            destinatarioId: widget.destinatarioId,
            contenido: base64Image,
            tipo: 'imagen',
          );
          // No recargar mensajes manualmente - el WebSocket se encarga
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen enviada (modo offline)'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      _startTyping();
    } else {
      _stopTyping();
    }
  }

  void _startTyping() {
    _chatService.startTyping(widget.destinatarioId);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    _chatService.stopTyping(widget.destinatarioId);
    _typingTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Widget de debug temporal - mostrar estado de conexión
        Container(
          padding: const EdgeInsets.all(8),
          color: _chatService.isConnected ? Colors.green[100] : Colors.red[100],
          child: Row(
            children: [
              Icon(
                _chatService.isConnected ? Icons.wifi : Icons.wifi_off,
                color: _chatService.isConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _chatService.isConnected ? 'Conectado' : 'Desconectado',
                style: TextStyle(
                  color: _chatService.isConnected ? Colors.green[800] : Colors.red[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Usuario: $_currentUserId',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Destinatario: ${widget.destinatarioId}',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  print('🔄 Botón de reconexión presionado');
                  await _chatService.initialize();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Reconectar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final msg = messages[i];
              final isMe = msg["isMe"] == true;

              Widget content;
              if (msg["tipo"] == 'imagen' && msg["text"] != null) {
                // Mostrar imagen - puede ser URL o base64
                final imageContent = msg["text"];
                print('🖼️ Procesando imagen: ${imageContent.substring(0, imageContent.length > 50 ? 50 : imageContent.length)}...');
                
                if (imageContent.startsWith('http') || imageContent.startsWith('/uploads')) {
                  // Es una URL
                  String imageUrl = imageContent;
                  if (imageContent.startsWith('/uploads')) {
                    // Construir URL completa según la plataforma
                    if (Platform.isAndroid) {
                      imageUrl = 'http://10.0.2.2:3001$imageContent';
                    } else {
                      imageUrl = 'http://localhost:3001$imageContent';
                    }
                  }
                  
                  print('🌐 URL de imagen: $imageUrl');
                  
                  content = ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      width: 220,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 220,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error cargando imagen URL: $error');
                        return Container(
                          width: 220,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  );
                } else if (imageContent.startsWith('data:image')) {
                  // Es base64
                  try {
                    print('📦 Decodificando imagen base64...');
                    final uri = Uri.dataFromString(imageContent);
                    final bytes = uri.data?.contentAsBytes();
                    
                    if (bytes != null && bytes.isNotEmpty) {
                      print('✅ Bytes obtenidos: ${bytes.length} bytes');
                      content = ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          bytes,
                          width: 220,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Error mostrando imagen base64: $error');
                            return Container(
                              width: 220,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      throw Exception('No se pudieron obtener los bytes de la imagen base64');
                    }
                  } catch (e) {
                    print('❌ Error procesando imagen base64: $e');
                    content = Container(
                      width: 220,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 30,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error cargando imagen',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  // Fallback: mostrar como texto
                  print('⚠️ Formato de imagen no reconocido: ${imageContent.substring(0, imageContent.length > 30 ? 30 : imageContent.length)}...');
                  content = Container(
                    width: 220,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Formato no soportado',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                // Mostrar texto
                content = Text(
                  msg["text"] ?? "",
                  style: TextStyle(
                    color: isMe ? AppColors.blanco : AppColors.textoOscuro,
                    fontSize: 15,
                    height: 1.25,
                  ),
                );
              }

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.azulPrimario
                        : AppColors.grisClaro.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: content,
                ),
              );
            },
          ),
        ),
        if (_isTyping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  '${widget.destinatarioNombre} está escribiendo...',
                  style: TextStyle(
                    color: AppColors.grisOscuro,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrimario),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            color: AppColors.blanco,
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo, color: AppColors.azulPrimario),
                  tooltip: "Enviar imagen",
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Grabación de audio desactivada."),
                      ),
                    );
                  },
                  icon: Icon(Icons.mic_none, color: AppColors.amarilloPrimario),
                  tooltip: "Audio (desactivado)",
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      onChanged: _onTextChanged,
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _sendText,
                  icon: Icon(Icons.send, color: AppColors.azulPrimario),
                  tooltip: "Enviar",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
