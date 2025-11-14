import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../widgets/create_user_dialog.dart';
import '../widgets/edit_user_dialog.dart';

class UserItem {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String usuario;
  final int rolId;
  final int estadoId;
  final String campus;
  bool isBanned;

  UserItem({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.usuario,
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
      usuario: json['usuario'] ?? '',
      rolId: json['rolId'] ?? 0,
      estadoId: json['estadoId'] ?? 0,
      campus: json['campus'] ?? '',
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
        Uri.parse("http://186.64.113.170:3001/api/admin/users"),
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

  void _onEdit(UserItem user) async {
    final updated = await showDialog(
      context: context,
      builder: (_) => EditUserDialog(user: user),
    );

    if (updated == true) {
      _refreshUsers();
    }
  }

  void _onDelete(UserItem user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar al usuario "${user.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.delete(
        Uri.parse("http://186.64.113.170:3001/api/admin/users/${user.id}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      } else {
        final error = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar usuario: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _toggleBanStatus(UserItem user) async {
    final newStatus = !user.isBanned;

    try {
      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.patch(
        Uri.parse("http://10.0.2.2:3001/api/admin/users/${user.id}/ban"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"banned": newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          user.isBanned = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Usuario baneado correctamente'
                  : 'Usuario desbaneado',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error al actualizar estado (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$userCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF0078A8)),
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
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person,
                color: user.isBanned ? Colors.red : const Color(0xFF00A8E8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      // 1. Añadido para que el texto no empuje al badge
                      child: Text(
                        "${user.nombre} ${user.apellido}",
                        style: TextStyle(
                          color: user.isBanned
                              ? Colors.red
                              : const Color(0xFF0078A8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // 2. Añadido para cortar texto
                        maxLines: 1, // 3. Añadido para una línea
                      ),
                    ),
                    if (user.isBanned)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VETADO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
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
              IconButton(
                icon: Icon(
                  user.isBanned ? Icons.block : Icons.check_circle,
                  color: user.isBanned ? Colors.red : Colors.green,
                ),
                onPressed: () => _toggleBanStatus(user),
                tooltip: user.isBanned ? 'Desbanear usuario' : 'Banear usuario',
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
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // <-- esto vuelve a /admin
        ),
        backgroundColor: const Color(0xFF00A8E8),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A8E8),
        onPressed: () async {
          final created = await showDialog(
            context: context,
            builder: (context) => const CreateUserDialog(),
          );
          if (created == true) {
            _refreshUsers(); // recarga la lista si se creó un usuario
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshUsers,
                // 1. Cambiamos ListView por ListView.builder
                child: ListView.builder(
                  // 2. Sumamos 3 items fijos (header, divider, title) al total
                  itemCount: _users.length + 3,
                  itemBuilder: (context, index) {
                    // 3. Dibujamos los items fijos primero
                    if (index == 0) {
                      return _buildHeader(context);
                    }
                    if (index == 1) {
                      return const Divider(height: 0, thickness: 0.5);
                    }
                    if (index == 2) {
                      return _buildTitle();
                    }
                    // 4. Calculamos el índice real del usuario (restando los 3 fijos)
                    final userIndex = index - 3;
                    final user = _users[userIndex];
                    return _buildUserCard(user);
                  },
                ),
              ),
      ),
    );
  }
}
