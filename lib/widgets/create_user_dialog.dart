// lib/widgets/create_user_dialog.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _rol; // Dejar nulo para que el hint funcione
  bool _isLoading = false;

  // --- Colores de tu app (Ajusta si es necesario) ---
  static const Color colorPrimario = Color(0xFF00A8E8);
  static const Color colorPrimarioOscuro = Color(0xFF0078A8);
  static const Color colorInputFondo = Color(0xFFF0F8FF);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Título Personalizado ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Crear Usuario',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorPrimarioOscuro,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),

                // --- Campos de Texto Estilizados ---
                _buildTextField(
                  controller: _nombreCtrl,
                  labelText: 'Nombre',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
                _buildTextField(
                  controller: _correoCtrl,
                  labelText: 'Correo',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                ),
                _buildTextField(
                  controller: _usuarioCtrl,
                  labelText: 'Usuario',
                  icon: Icons.account_circle,
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
                _buildTextField(
                  controller: _passwordCtrl,
                  labelText: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                _buildDropdownField(
                  value: _rol,
                  hintText: 'Seleccione Rol',
                  icon: Icons.assignment_ind,
                  items: ['Administrador', 'Vendedor', 'Cliente']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                  validator: (value) => value == null ? 'Seleccione un rol' : null,
                ),

                const SizedBox(height: 24),

                // --- Botón de Acción Estilizado ---
                _isLoading
                    ? const CircularProgressIndicator(color: colorPrimario)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            elevation: 5,
                            shadowColor: colorPrimario.withOpacity(0.4),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Crear'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Helper para Inputs ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: colorPrimario),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorInputFondo,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: colorPrimario, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // --- Widget Helper para Dropdowns ---
  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: colorPrimario),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorInputFondo,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: colorPrimario, width: 2),
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        icon: const Icon(Icons.arrow_drop_down, color: colorPrimario),
      ),
    );
  }

  // --- Lógica de Creación (Sin cambios) ---
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();
    final rolId = _rol == 'Administrador' ? 1 : _rol == 'Vendedor' ? 2 : 3;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3001/api/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': _nombreCtrl.text,
        'correo': _correoCtrl.text,
        'usuario': _usuarioCtrl.text,
        'contrasena': _passwordCtrl.text,
        'rolId': rolId,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado correctamente')),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear usuario: ${response.body}')),
      );
    }
  }
}