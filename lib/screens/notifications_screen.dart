import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mockNotifications = [
      {
        'title': 'Nuevo comentario',
        'message': 'Juan comentó en tu publicación: "¡Buen producto!"'
      },
      {
        'title': 'Valoración recibida',
        'message': 'Tu publicación fue valorada con 5 estrellas.'
      },
      {
        'title': 'Nueva oferta',
        'message': 'Ana hizo una oferta por tu producto.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = mockNotifications[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.amber),
              title: Text(notif['title']!),
              subtitle: Text(notif['message']!),
              trailing: IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notificación marcada como leída')),
                  );
                },
              ),
              onTap: () {
                if (notif['title'] == 'Valoración recibida') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('¡Has recibido una valoración!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tu producto fue calificado con:'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return const Icon(Icons.star, color: Colors.amber);
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '"Excelente calidad y entrega rápida. ¡Gracias!"',
                            style: TextStyle(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notificación: ${notif['message']}')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}