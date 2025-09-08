// lib/screens/admin_menu_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administrador'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Administrar usuarios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                context.push('/admin/users');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.report),
              label: const Text('Ver reportes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad aún no implementada')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}