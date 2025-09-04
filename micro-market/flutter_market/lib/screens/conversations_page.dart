import 'package:flutter/material.dart';
import '../widgets/chat_view.dart';
import '../widgets/theme.dart';

class ConversationsPage extends StatelessWidget {
  final List<Map<String, String>> conversations = [
    {
      "name": "Dr. Elisa Jones",
      "lastMessage": "Ok!",
      "time": "9:41 AM",
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
    {
      "name": "Juan Pérez",
      "lastMessage": "Nos vemos mañana",
      "time": "8:20 AM",
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
    {
      "name": "María González",
      "lastMessage": "Te mando el link",
      "time": "Ayer",
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final chat = conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat["avatar"]!),
            ),
            title: Text(chat["name"]!),
            subtitle: Text(chat["lastMessage"]!),
            trailing: Text(chat["time"]!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    userName: chat["name"]!,
                    avatar: chat["avatar"]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final String userName;
  final String avatar;

  ChatPage({required this.userName, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(avatar)),
            const SizedBox(width: 10),
            Text(userName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.white),
            onPressed: () {
              // Aquí luego puedes integrar llamadas (VoIP / Teléfono)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Función de llamada no implementada"),
                ),
              );
            },
          ),
        ],
      ),
      body: ChatView(),
    );
  }
}
