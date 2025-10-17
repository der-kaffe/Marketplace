import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  bool _isLoadingMessages = true;
  bool _isUploadingImage = false;
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
    try {
      setState(() {
        _isLoadingMessages = true;
      });

      // Asegurar que tenemos el currentUserId antes de cargar mensajes
      if (_currentUserId == null) {
        await _loadCurrentUser();
      }

      final messagesList =
          await _chatService.getMessages(widget.destinatarioId);

      setState(() {
        messages.clear();
        messages.addAll(messagesList.map(
            (msg) => _chatService.formatMessage(msg, _currentUserId ?? 0)));
        _isLoadingMessages = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('❌ Error cargando mensajes: $e');
      setState(() {
        _isLoadingMessages = false;
      });
    }
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

      final isFromThisConversation = (remitenteId == _currentUserId &&
              destinatarioId == widget.destinatarioId) ||
          (remitenteId == widget.destinatarioId &&
              destinatarioId == _currentUserId);

      print('✅ Es de esta conversación: $isFromThisConversation');

      if (isFromThisConversation) {
        // Verificar si el mensaje ya existe para evitar duplicados
        final messageId = message['id'];
        final exists = messages.any((msg) => msg['id'] == messageId);

        print('📝 Mensaje ya existe: $exists');

        if (!exists) {
          final formattedMessage =
              _chatService.formatMessage(message, _currentUserId ?? 0);
          print('➕ Agregando mensaje formateado: $formattedMessage');

          setState(() {
            // Buscar y remover mensaje temporal si existe
            final tempIndex = messages.indexWhere((msg) =>
                msg['temp'] == true &&
                msg['text'] == formattedMessage['text'] &&
                msg['remitenteId'] == formattedMessage['remitenteId']);

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
    _connectionSubscription =
        _chatService.connectionStream.listen((isConnected) {
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
      setState(() {
        _isUploadingImage = true;
      });

      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (img == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
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

      setState(() {
        _isUploadingImage = false;
      });
    } catch (e) {
      print('❌ Error seleccionando imagen: $e');
      setState(() {
        _isUploadingImage = false;
      });
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

  // Función mejorada para manejar imágenes base64
  Widget _buildBase64Image(String base64Content) {
    try {
      print('📦 Procesando imagen base64...');

      // Validar y limpiar el contenido base64
      final cleanedContent = _validateAndCleanBase64(base64Content);
      if (cleanedContent == null) {
        throw Exception('Contenido base64 inválido o corrupto');
      }

      // Decodificar base64
      final bytes = base64Decode(cleanedContent);

      if (bytes.isEmpty) {
        throw Exception('Imagen base64 vacía');
      }

      // Validar que los bytes sean de una imagen válida
      if (!_isValidImageBytes(bytes)) {
        throw Exception('Los bytes no corresponden a una imagen válida');
      }

      print('✅ Bytes decodificados exitosamente: ${bytes.length} bytes');

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          bytes,
          width: 220,
          height: 200,
          fit: BoxFit.cover,
          gaplessPlayback: true, // Evitar parpadeo
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error renderizando imagen base64: $error');
            return _buildImageErrorWidget('Error renderizando imagen');
          },
        ),
      );
    } catch (e) {
      print('❌ Error procesando imagen base64: $e');
      return _buildImageErrorWidget('Error procesando imagen');
    }
  }

  // Validar y limpiar contenido base64
  String? _validateAndCleanBase64(String base64Content) {
    try {
      // Validar formato base64
      if (!base64Content.contains(',')) {
        print('❌ Formato base64 inválido: falta separador');
        return null;
      }

      // Extraer solo la parte base64 (después de la coma)
      final parts = base64Content.split(',');
      if (parts.length != 2) {
        print('❌ Formato base64 inválido: estructura incorrecta');
        return null;
      }

      final mimeType = parts[0];
      final base64Data = parts[1];

      print('🔍 MIME type: $mimeType');
      print('📏 Longitud base64: ${base64Data.length} caracteres');

      // Validar que sea una imagen
      if (!mimeType.contains('image/')) {
        print('❌ No es un tipo de imagen válido: $mimeType');
        return null;
      }

      // Limpiar caracteres problemáticos (espacios, saltos de línea, etc.)
      final cleanBase64 = base64Data.replaceAll(RegExp(r'\s'), '');

      // Validar que el string base64 sea válido
      if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(cleanBase64)) {
        print('❌ Caracteres inválidos en base64');
        return null;
      }

      return cleanBase64;
    } catch (e) {
      print('❌ Error validando base64: $e');
      return null;
    }
  }

  // Validar que los bytes correspondan a una imagen válida
  bool _isValidImageBytes(List<int> bytes) {
    if (bytes.length < 4) return false;

    // Verificar firmas de archivos de imagen comunes
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return true;
    }

    // BMP: 42 4D (BM)
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }

    print('⚠️ Formato de imagen no reconocido en los bytes');
    return false;
  }

  // Widget para mostrar errores de imagen
  Widget _buildImageErrorWidget(String message) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Widget de carga personalizado con logo
  Widget _buildCustomLoadingWidget({
    String message = 'Cargando...',
    double size = 60.0,
  }) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado
          _buildAnimatedLogo(size: size),
          const SizedBox(height: 16),
          // Texto de carga
          Text(
            message,
            style: TextStyle(
              color: AppColors.azulPrimario,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Puntos animados
          _buildLoadingDots(),
        ],
      ),
    );
  }

  // Logo animado
  Widget _buildAnimatedLogo({double size = 60.0}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159, // Rotación completa
          child: Transform.scale(
            scale: 0.8 +
                (0.4 * (0.5 + 0.5 * sin(value * 3.14159))), // Escala pulsante
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.azulPrimario,
                    AppColors.azulPrimario.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulPrimario.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school, // Icono de universidad
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Reiniciar la animación
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // Puntos de carga animados
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.azulPrimario.withOpacity(0.3 + (0.7 * value)),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {
            if (mounted) {
              setState(() {});
            }
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _isLoadingMessages
                  ? Center(
                      child: _buildCustomLoadingWidget(
                        message: 'Cargando conversación...',
                        size: 80,
                      ),
                    )
                  : ListView.builder(
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
                          print(
                              '🖼️ Procesando imagen: ${imageContent.substring(0, imageContent.length > 50 ? 50 : imageContent.length)}...');

                          if (imageContent.startsWith('http') ||
                              imageContent.startsWith('/uploads')) {
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
                                gaplessPlayback: true, // Evitar parpadeo
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return _buildCustomLoadingWidget(
                                    message: 'Cargando imagen...',
                                    size: 50,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Error cargando imagen URL: $error');
                                  return _buildImageErrorWidget(
                                      'Error cargando imagen');
                                },
                              ),
                            );
                          } else if (imageContent.startsWith('data:image')) {
                            // Es base64 - usar función mejorada
                            content = _buildBase64Image(imageContent);
                          } else {
                            // Fallback: mostrar como texto
                            print(
                                '⚠️ Formato de imagen no reconocido: ${imageContent.substring(0, imageContent.length > 30 ? 30 : imageContent.length)}...');
                            content =
                                _buildImageErrorWidget('Formato no soportado');
                          }
                        } else {
                          // Mostrar texto
                          content = Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              color: isMe
                                  ? AppColors.blanco
                                  : AppColors.textoOscuro,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          );
                        }

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.azulPrimario),
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
                      onPressed: _isUploadingImage ? null : _pickImage,
                      icon: _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.azulPrimario),
                              ),
                            )
                          : Icon(Icons.photo, color: AppColors.azulPrimario),
                      tooltip: _isUploadingImage
                          ? "Subiendo imagen..."
                          : "Enviar imagen",
                    ),
                    // Botón de audio - desactivado por ahora
                    // IconButton(
                    //   onPressed: () {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text("Grabación de audio desactivada."),
                    //       ),
                    //     );
                    //   },
                    //   icon: Icon(Icons.mic_none,
                    //       color: AppColors.amarilloPrimario),
                    //   tooltip: "Audio (desactivado)",
                    // ),
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
        ),
        // Overlay de carga para subida de imagen
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: _buildCustomLoadingWidget(
                  message: 'Subiendo imagen...',
                  size: 100,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
