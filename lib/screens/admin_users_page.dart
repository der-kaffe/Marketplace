import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class UserItem {
  final int id;
  final String name;
  final String email;
  final String subtitle;
  bool isBanned; 

  UserItem({
    required this.id,
    required this.name,
    required this.email,
    this.subtitle = 'Lorem ipsum dolor, consectetur.',
    this.isBanned = false, 
  });
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  // Datos de ejemplo: reemplaza por la llamada a tu API
  final List<UserItem> _users = [
    UserItem(id: 1, name: 'Juan Pérez', email: 'juan@ejemplo.com'),
    UserItem(id: 2, name: 'María Gómez', email: 'maria@ejemplo.com'),
    UserItem(id: 3, name: 'Luis Fernández', email: 'luis@ejemplo.com'),
    UserItem(id: 4, name: 'Usuario 4', email: 'usuario4@ejemplo.com'),
    UserItem(id: 5, name: 'Usuario 5', email: 'usuario5@ejemplo.com'),
    UserItem(id: 6, name: 'Usuario 6', email: 'usuario6@ejemplo.com'),
  ];

  Future<void> _refreshUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
    });
  }

  void _onEdit(UserItem user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar: ${user.name} (a implementar)')),
    );
  }

  void _onDelete(UserItem user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar al usuario "${user.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
    }
  }

  Widget _buildHeader(BuildContext context) {
    final userCount = _users.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hola Administrador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Panel de usuarios',
                style: TextStyle(fontSize: 13, color: Color(0xFFF6B400)), // amarillo suave
              ),
            ],
          ),

          const Spacer(),

          // Badge con número de usuarios (círculo)
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBEEAF5), Color(0xFFE7FEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withAlpha(31), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$userCount',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0078A8)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Número de\nUsuarios',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Text(
          'Lista de usuarios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserItem user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCFB), // aqua claro
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF00A8E8).withAlpha(38), width: 1.5),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, size: 28, color: Color(0xFF00A8E8)),
            ),
          ),
          const SizedBox(width: 12),
          // nombre + subtítulo

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        color: user.isBanned ? Colors.red : const Color(0xFF0078A8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (user.isBanned)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VETADO',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // acciones (editar / eliminar)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit icon (azul)
              InkWell(
                onTap: () => _onEdit(user),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF00A8E8).withAlpha(38)),
                  ),
                  child: const Icon(Icons.edit, color: Color(0xFF00A8E8), size: 18),
                ),
              ),
              const SizedBox(height: 8),
              // Delete icon (rojo)
              InkWell(
                onTap: () => _onDelete(user),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(31)),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Implementación de vetado
              InkWell(
                onTap: () {
                  setState(() {
                    user.isBanned = !user.isBanned;  // alternar estado
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(user.isBanned ? 'Usuario vetado' : 'Usuario desvetado')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.isBanned ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: user.isBanned ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Icon(
                    user.isBanned ? Icons.block : Icons.check_circle,
                    color: user.isBanned ? Colors.red : Colors.green,
                    size: 18,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      // floating action button parecido al diseño
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A8E8),
        onPressed: () {
          // pantalla para agregar usuario
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregar usuario (a implementar)')));
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUsers,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 0, thickness: 0.5),
              _buildTitle(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20, top: 6),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return _buildUserCard(u);
                  },
                ),
              ),
            ],
          ),
        ),      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar la sesión de administrador?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final authService = AuthService();
                  await authService.logout();
                } catch (e) {
                  debugPrint("Error al cerrar sesión: $e");
                }

                // Ir a login
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}