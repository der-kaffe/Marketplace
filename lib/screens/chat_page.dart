import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_view.dart';
import '../theme/app_colors.dart';

class ChatPage extends StatelessWidget {
  final String userName;
  final String avatar;
  final int destinatarioId;

  const ChatPage({
    Key? key, 
    required this.userName, 
    required this.avatar,
    required this.destinatarioId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
          Expanded(
            child: ChatView(
              destinatarioId: destinatarioId,
              destinatarioNombre: userName,
            ),
          ),
        ],
      ),
    );
  }
}
