import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> conversations = [
    {
      "name": "Dr. Elisa Jones",
      "lastMessage": "Ok!",
      "time": "9:41 AM",
      "unread": 2,
      "avatar":
          "https://plus.unsplash.com/premium_photo-1689551670902-19b441a6afde?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFuZG9tJTIwcGVvcGxlfGVufDB8fDB8fHww",
    },
    {
      "name": "Juan Pérez",
      "lastMessage": "Nos vemos mañana",
      "time": "8:20 AM",
      "unread": 0,
      "avatar":
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cmFuZG9tJTIwcGVvcGxlfGVufDB8fDB8fHww",
    },
    {
      "name": "María González",
      "lastMessage": "Te mando el link",
      "time": "Ayer",
      "unread": 5,
      "avatar":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8cmFuZG9tJTIwcGVvcGxlfGVufDB8fDB8fHww",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        title: const Text("Chats", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppColors.grisClaro, height: 1),
        itemBuilder: (context, index) {
          final chat = conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat["avatar"]),
              backgroundColor: AppColors.grisClaro,
              onBackgroundImageError: (_, __) {},
            ),
            title: Text(
              chat["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              chat["lastMessage"],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textoOscuro),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chat["time"],
                  style: TextStyle(color: AppColors.grisOscuro, fontSize: 12),
                ),
                if (chat["unread"] > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.azulPrimario,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${chat["unread"]}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatPage(userName: chat["name"], avatar: chat["avatar"]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.azulPrimario,
        onPressed: () {
          // Acción: nuevo chat
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
