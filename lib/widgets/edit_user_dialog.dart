import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../screens/admin_users_page.dart';

class EditUserDialog extends StatefulWidget {
  final UserItem user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _campusCtrl;
  late TextEditingController _usuarioCtrl;
  String _rol = 'Cliente';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user.nombre);
    _correoCtrl = TextEditingController(text: widget.user.correo);
    _usuarioCtrl = TextEditingController(text: widget.user.usuario); 
    _campusCtrl = TextEditingController(text: widget.user.campus);

    switch (widget.user.rolId) {
      case 1:
        _rol = 'Administrador';
        break;
      case 2:
        _rol = 'Vendedor';
        break;
      default:
        _rol = 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
              ),
              TextFormField(
                controller: _usuarioCtrl,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _campusCtrl,
                decoration: const InputDecoration(labelText: 'Campus'),
              ),
              DropdownButtonFormField<String>(
                value: _rol,
                items: ['Administrador', 'Vendedor', 'Cliente']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _rol = v!),
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();
    final rolId = _rol == 'Administrador' ? 1 : _rol == 'Vendedor' ? 2 : 3;

    final response = await http.put(
      Uri.parse('http://10.0.2.2:3001/api/admin/${widget.user.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': _nombreCtrl.text,
        'correo': _correoCtrl.text,
        'usuario': _usuarioCtrl.text,
        'rolId': rolId,
        'campus': _campusCtrl.text,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado correctamente')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${response.body}')),
      );
    }
  }
}