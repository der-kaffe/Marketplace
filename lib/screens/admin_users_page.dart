import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class UserItem {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final int rolId;
  final int estadoId;
  final String campus;
  bool isBanned;

  UserItem({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rolId,
    required this.estadoId,
    required this.campus,
    this.isBanned = false,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      correo: json['correo'] ?? '',
      rolId: json['rolId'] ?? 0,
      estadoId: json['estadoId'] ?? 0,
      campus: json['campus'] ?? '',
      // si tu backend expone estadoId == X para baneado, puedes mapearlo aquí
      isBanned: (json['estadoId'] == 2), // ejemplo: 2 = baneado
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<UserItem> _users = [];
  bool _loading = true;

  Future<void> _refreshUsers() async {
    try {
      setState(() => _loading = true);

      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse("http://10.0.2.2:3001/api/admin/users"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawUsers = data['users'] ?? [];

        setState(() {
          _users = rawUsers.map((j) => UserItem.fromJson(j)).toList();
        });
      } else {
        debugPrint("Error al obtener usuarios: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar usuarios')),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _onEdit(UserItem user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar: ${user.nombre} (a implementar)')),
    );
  }

  void _onDelete(UserItem user) async {
    // aquí puedes llamar a DELETE /api/admin/users/:id en backend
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar al usuario "${user.nombre}"?'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado (API pendiente)')),
      );
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
                style: TextStyle(fontSize: 13, color: Color(0xFFF6B400)),
              ),
            ],
          ),
          const Spacer(),
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

  Widget _buildUserCard(UserItem user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCFB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: user.isBanned ? Colors.red : const Color(0xFF00A8E8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${user.nombre} ${user.apellido}",
                      style: TextStyle(
                        color: user.isBanned ? Colors.red : const Color(0xFF0078A8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (user.isBanned)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.correo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF00A8E8)),
                onPressed: () => _onEdit(user),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _onDelete(user),
              ),
            ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A8E8),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregar usuario (a implementar)')));
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshUsers,
                child: ListView(
                  children: [
                    _buildHeader(context),
                    const Divider(height: 0, thickness: 0.5),
                    _buildTitle(),
                    ..._users.map((u) => _buildUserCard(u)).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar la sesión de administrador?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authService = AuthService();
                await authService.logout();
              } catch (e) {
                debugPrint("Error al cerrar sesión: $e");
              }
              if (context.mounted) context.go('/login');
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}