import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<Map<String, dynamic>> messages = [
    {"text": "Hola, ¿Cómo estás?", "isMe": false},
    {"text": "Bien y tu?!", "isMe": true},
    {"text": "Muy bien", "isMe": false},
    {"text": "Gracias!", "isMe": false},
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({"text": _controller.text, "isMe": true});
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
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
                  decoration: BoxDecoration(
                    color: msg["isMe"] ? AppColors.primaryBlue : AppColors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg["text"],
                    style: TextStyle(
                      color: msg["isMe"] ? AppColors.white : AppColors.black,
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
          color: AppColors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo, color: AppColors.primaryBlue),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: AppColors.accentYellow),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Escribe un mensaje...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
