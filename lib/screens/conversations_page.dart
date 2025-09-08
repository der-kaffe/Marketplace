import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_view.dart';
import '../theme/app_colors.dart';

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

  ConversationsPage({super.key});

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
              print('Error cargando avatar: $exception');
            },
          ),
          title: Text(chat["name"]!),
          subtitle: Text(chat["lastMessage"]!),
          trailing: Text(chat["time"]!),
          onTap: () {
            print('Navegando a chat con ${chat["name"]}');

            // Usar push en lugar de go para mantener el stack de navegación
            context.push(
              '/home/chat/${Uri.encodeComponent(chat["name"]!)}'
              '?avatar=${Uri.encodeComponent(chat["avatar"]!)}',
            );
          },
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  final String userName;
  final String avatar;

  const ChatPage({super.key, required this.userName, required this.avatar});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void dispose() {
    // Limpiar recursos cuando se sale del chat
    print('Saliendo del chat con ${widget.userName}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AppBar personalizado
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            color: AppColors.azulPrimario,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () {
                    // Usar pop en lugar de go para volver correctamente
                    context.pop();
                  },
                ),
                CircleAvatar(
                  backgroundImage: widget.avatar.isNotEmpty
                      ? NetworkImage(widget.avatar)
                      : null,
                  child: widget.avatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.userName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blanco,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.blanco),
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
          ),
          // Contenido del chat
          Expanded(
            child: ChatView(
              key: ValueKey(widget.userName), // Key única para cada chat
            ),
          ),
        ],
      ),
    );
  }
}
