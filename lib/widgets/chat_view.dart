import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<Map<String, dynamic>> messages = [
    {"text": "Hola, ¿Cómo estás?", "isMe": false},
    {"text": "¡Bien! ¿y tú?", "isMe": true},
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
    setState(() => messages.add({"text": text, "isMe": true}));
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() => messages.add({"image": img.path, "isMe": true}));
    _scrollToBottom();
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
