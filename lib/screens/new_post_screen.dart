import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  String? category;
  String? _previewUrl; // solo visual

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.azulPrimario,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 12),
              const Text('¡Publicación creada!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tu publicación próximamente funcionará.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Crear otra: solo limpiamos campos y cerramos el sheet
                        _formKey.currentState?.reset();
                        _titleCtrl.clear();
                        _descCtrl.clear();
                        _priceCtrl.clear();
                        _imageUrlCtrl.clear();
                        setState(() {
                          category = null;
                          _previewUrl = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Crear otra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);   // cerrar sheet
                        context.go('/home');      // navegar directamente al home usando GoRouter
                      },
                      child: const Text('Volver al inicio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva publicación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Preview/Selector de imagen (visual)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grisClaro),
                  color: Colors.grey.shade100,
                ),
                clipBehavior: Clip.antiAlias,
                child: _previewUrl == null || _previewUrl!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_outlined, size: 40, color: AppColors.grisPrimario),
                            const SizedBox(height: 8),
                            const Text('Imagen de portada', style: TextStyle(color: AppColors.grisPrimario)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showComingSoon('Subir desde galería/cámara'),
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Subir'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // usar URL (mock) -> solo visual
                                    _showComingSoon('Selector de archivos — usando URL por ahora');
                                  },
                                  icon: const Icon(Icons.link),
                                  label: const Text('Usar URL'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Ink.image(
                        image: NetworkImage(_previewUrl!),
                        fit: BoxFit.cover,
                        child: InkWell(
                          onTap: () => _showComingSoon('Editor de imagen'),
                        ),
                      ),
              ),

              spacing,

              // Campo para pegar URL de imagen y actualizar preview
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                  suffixIcon: IconButton(
                    tooltip: 'Previsualizar',
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      setState(() => _previewUrl = _imageUrlCtrl.text.trim());
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
              ),
              spacing,
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
              ),
              spacing,
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa un precio';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Precio inválido';
                  return null;
                },
              ),
              spacing,
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                initialValue: category,
                items: const [
                  DropdownMenuItem(value: 'electronica', child: Text('Electrónica')),
                  DropdownMenuItem(value: 'ropa', child: Text('Ropa')),
                  DropdownMenuItem(value: 'deportes', child: Text('Deportes')),
                  DropdownMenuItem(value: 'joyas', child: Text('Joyas')),
                  DropdownMenuItem(value: 'belleza', child: Text('Belleza')),
                  DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                ],
                onChanged: (value) => setState(() => category = value),
                validator: (v) => (v == null || v.isEmpty) ? 'Selecciona una categoría' : null,
              ),

              const SizedBox(height: 20),

              // Lugar de encuentro (deshabilitado por ahora)
              TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Lugar de encuentro (próximamente)',
                  hintText: 'Seleccionar en mapa / campus',
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Mock: simular guardado y mostrar "no pantalla en blanco"
                    await _showSuccessSheet();
                    // No llamamos a Navigator.pop directo aquí; lo maneja el sheet.
                  }
                },
                child: const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
