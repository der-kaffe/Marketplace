import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_view.dart';
import '../core/theme/theme.dart';

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
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final chat = conversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(chat["avatar"]!),
            onBackgroundImageError: (exception, stackTrace) {
            },
          ),
          title: Text(chat["name"]!),
          subtitle: Text(chat["lastMessage"]!),
          trailing: Text(chat["time"]!),
          onTap: () {
            print('Navegando a chat con ${chat["name"]}');

            context.go(
              '/home/chat/${Uri.encodeComponent(chat["name"]!)}'
              '?avatar=${Uri.encodeComponent(chat["avatar"]!)}',
            );
          },
        );
      },
    );
  }
}

class ChatPage extends StatelessWidget {
  final String userName;
  final String avatar;

  const ChatPage({super.key, required this.userName, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white, // Asegurar que el texto sea blanco
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? Icon(Icons.person) : null,
              onBackgroundImageError: (exception, stackTrace) {
                // Manejo de error si la imagen no carga
              },
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(userName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Función de llamada no implementada"),
                ),
              );
            },
          ),
        ],
      ),
      body: const ChatView(), 
    );
  }
}
