import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> conversations = [];
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('🚀 Inicializando chat...');
    await _loadCurrentUser();
    await _loadConversations();
    _setupWebSocketListeners();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Cargando conversaciones...');
      print('👤 Usuario actual ID: $_currentUserId');
      
      final conversationsList = await _chatService.getConversations();
      print('📋 Conversaciones obtenidas del servicio: ${conversationsList.length}');
      
      for (int i = 0; i < conversationsList.length; i++) {
        print('   ${i + 1}. ${conversationsList[i]}');
      }
      
      setState(() {
        conversations = conversationsList.map((conv) => 
          _chatService.formatConversation(conv, _currentUserId ?? 0)
        ).toList();
        _isLoading = false;
      });
      
      print('✅ Conversaciones formateadas: ${conversations.length}');
      for (int i = 0; i < conversations.length; i++) {
        print('   ${i + 1}. ${conversations[i]["name"]}: "${conversations[i]["lastMessage"]}"');
      }
    } catch (e) {
      print('❌ Error cargando conversaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupWebSocketListeners() {
    _chatService.messageStream.listen((message) {
      // Actualizar la lista de conversaciones cuando llegue un nuevo mensaje
      _loadConversations();
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
          destinatarioId: chat["id"],
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
          : conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.grisOscuro,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes conversaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.grisOscuro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia una conversación con alguien',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulPrimario,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Recargar'),
                      ),
                    ],
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat["lastMessage"],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textoOscuro,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                chat["time"],
                                style: TextStyle(
                                  color: AppColors.grisOscuro,
                                  fontSize: 12,
                                ),
                              ),
                              if (chat["isMe"])
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.azulPrimario.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Enviado",
                                    style: TextStyle(
                                      color: AppColors.azulPrimario,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (chat["unread"] > 0)
                            Container(
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
