import 'package:flutter/material.dart';

class AdminUsersPage extends StatelessWidget {
  AdminUsersPage({super.key});

  final List<Map<String, String>> users = [
    {"name": "Juan Pérez", "email": "juan@example.com"},
    {"name": "María Gómez", "email": "maria@example.com"},
    {"name": "Luis Fernández", "email": "luis@example.com"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Usuarios')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(child: Text(user["name"]![0])),
            title: Text(user["name"]!),
            subtitle: Text(user["email"]!),
            onTap: () {
            },
          );
        },
      ),
    );
  }
}