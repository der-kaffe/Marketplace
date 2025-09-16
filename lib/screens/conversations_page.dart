import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  bool _isLoading = true;

  final List<Map<String, dynamic>> conversations = [
    {
      "name": "Dr. Elisa Jones",
      "lastMessage": "Ok!",
      "time": "9:41 AM",
      "unread": 2,
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
    {
      "name": "Juan Pérez",
      "lastMessage": "Nos vemos mañana",
      "time": "8:20 AM",
      "unread": 0,
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
    {
      "name": "María González",
      "lastMessage": "Te mando el link",
      "time": "Ayer",
      "unread": 5,
      "avatar":
          "https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simula carga inicial (puedes reemplazarlo con fetch real de API)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _openChat(int index) async {
    final chat = conversations[index];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          userName: chat["name"],
          avatar: chat["avatar"],
        ),
      ),
    );

    setState(() {
      conversations[index]["unread"] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        title: const Text(
          "Chats",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 40.0,
              ),
            )
          : ListView.separated(
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
                        style: TextStyle(
                            color: AppColors.grisOscuro, fontSize: 12),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => _openChat(index),
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
