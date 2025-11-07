import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class CommunityChatView extends StatefulWidget {
  const CommunityChatView({super.key});

  @override
  State<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  int? _currentUserId;
  StreamSubscription? _groupSub;
  final Set<dynamic> _messageIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?['id'];
      });
    }

    await _chatService.initialize();

    // Cargar historial
    final history = await _chatService.getCommunityMessages(limit: 80);
    if (mounted) {
      setState(() {
        _messages.clear();
        _messageIds.clear();
        for (final m in history) {
          final id = m['id'];
          if (id != null && !_messageIds.contains(id)) {
            _messages.add(m);
            _messageIds.add(id);
          }
        }
        _isLoading = false;
      });
    }
    _scrollToBottom();

    // Suscribir a mensajes de comunidad
    _groupSub = _chatService.groupMessageStream.listen((data) {
      if (!mounted) return;
      final int? realId = data['id'];
      final String? contenido = data['contenido'];
      final int? remitenteId = data['remitenteId'];

      setState(() {
        // Reemplazar temporal si coincide por contenido y remitente
        final tempIndex = _messages.indexWhere((m) =>
            m['temp'] == true &&
            m['contenido'] == contenido &&
            m['remitenteId'] == remitenteId);
        if (tempIndex != -1) {
          _messages[tempIndex] = data;
          if (realId != null) _messageIds.add(realId);
          return;
        }

        // Evitar duplicados por id
        if (realId != null && _messageIds.contains(realId)) {
          return;
        }

        _messages.add(data);
        if (realId != null) _messageIds.add(realId);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // Optimista
    final temp = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'contenido': text,
      'tipo': 'texto',
      'remitenteId': _currentUserId,
      'remitente': {'id': _currentUserId, 'nombre': 'Tú'},
      'fechaEnvio': DateTime.now().toIso8601String(),
      'room': 'room_comunidad_uct',
      'temp': true,
    };
    setState(() {
      _messages.add(temp);
    });
    _scrollToBottom();

    try {
      await _chatService.sendGroupMessage(contenido: text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == temp['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error enviando: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(
                  child: _buildCustomLoadingWidget(
                    message: 'Cargando mensajes de comunidad...',
                    size: 80,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    final isMe = msg['remitenteId'] == _currentUserId;
                    final nombre = msg['remitente']?['nombre'] ?? 'Usuario';
                    final contenido = msg['contenido'] ?? '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.azulPrimario
                              : AppColors.grisClaro.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // Mostrar nombre arriba del mensaje en comunidad
                            Text(
                              isMe ? 'Tú' : nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isMe
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.textoOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contenido,
                              style: TextStyle(
                                color:
                                    isMe ? Colors.white : AppColors.textoOscuro,
                                fontSize: 15,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mensaje para Comunidad UCT...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _send,
                  icon: Icon(Icons.send, color: AppColors.azulPrimario),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========= Loading UI similar a chat antiguo =========
  Widget _buildCustomLoadingWidget({
    String message = 'Cargando...',
    double size = 60.0,
  }) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedLogo(size: size),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.azulPrimario,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildLoadingDots(),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo({double size = 60.0}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Transform.scale(
            scale: 0.8 + (0.4 * (0.5 + 0.5 * sin(value * 3.14159))),
            child: Container(
              width: size,
              height: size,
              child: Image.asset(
                'assets/logoMarket.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.azulPrimario.withOpacity(0.3 + (0.7 * value)),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {
            if (mounted) setState(() {});
          },
        );
      }),
    );
  }
}
