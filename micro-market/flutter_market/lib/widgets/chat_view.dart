import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<Map<String, dynamic>> messages = [
    {"text": "Hola, ¿Cómo estás?", "isMe": false},
    {"text": "Bien y tu?!", "isMe": true},
    {"text": "Muy bien", "isMe": false},
    {"text": "Gracias!", "isMe": false},
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Limpiar controladores para evitar memory leaks
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        messages.add({"text": _controller.text.trim(), "isMe": true});
      });
      _controller.clear();

      // Scroll automático al último mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Align(
                alignment: msg["isMe"]
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: msg["isMe"] ? AppColors.azulPrimario : AppColors.grisClaro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg["text"],
                    style: TextStyle(
                      color: msg["isMe"] ? AppColors.blanco : AppColors.textoOscuro,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: AppColors.blanco,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo, color: AppColors.azulPrimario),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Función de fotos no implementada"),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: AppColors.amarilloPrimario),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Función de audio no implementada"),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.azulPrimario),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
