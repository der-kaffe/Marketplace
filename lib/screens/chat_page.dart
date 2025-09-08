import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_view.dart';
import '../theme/app_colors.dart';

/// Página para mostrar un chat individual
class ChatPage extends StatelessWidget {
  final String userName;
  final String avatar;

  const ChatPage({super.key, required this.userName, required this.avatar});

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
                  icon: Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundImage: NetworkImage(avatar),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error cargando avatar: $exception');
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  userName,
                  style: TextStyle(
                    color: AppColors.blanco,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.call, color: AppColors.blanco),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Contenido del chat
          const Expanded(
            child: ChatView(),
          ),
        ],
      ),
    );
  }
}
