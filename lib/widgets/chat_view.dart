import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

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
  
  int? _currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _setupWebSocketListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
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
    _chatService.messageStream.listen((message) {
      final formattedMessage = _chatService.formatMessage(message, _currentUserId ?? 0);
      
      // Solo agregar mensajes de esta conversación
      if (formattedMessage['isMe'] || 
          (message['remitenteId'] == widget.destinatarioId) ||
          (message['destinatarioId'] == widget.destinatarioId)) {
        setState(() {
          messages.add(formattedMessage);
        });
        _scrollToBottom();
      }
    });

    _chatService.typingStream.listen((data) {
      if (data['userId'] == widget.destinatarioId) {
        setState(() {
          _isTyping = data['isTyping'] ?? false;
        });
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

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _chatService.sendMessage(
      destinatarioId: widget.destinatarioId,
      contenido: text,
    );
    
    _controller.clear();
    _stopTyping();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    
    _chatService.sendMessage(
      destinatarioId: widget.destinatarioId,
      contenido: img.path,
      tipo: 'imagen',
    );
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
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final msg = messages[i];
              final isMe = msg["isMe"] == true;

              Widget content;
              if (msg["image"] != null) {
                content = ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(msg["image"]),
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
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
