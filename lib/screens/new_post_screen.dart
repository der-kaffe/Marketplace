import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../models/product_model.dart' as ProductModel;

class NewPostScreen extends StatefulWidget {
  final VoidCallback? onProductCreated;

  const NewPostScreen({
    super.key, 
    this.onProductCreated,
  });

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _imageUrlCtrl = TextEditingController();
  final ProductService _productService = ProductService();

  int? _selectedCategoryId;
  String? _previewUrl;
  bool _isLoading = false;
  List<ProductModel.ApiCategory> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.fetchCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando categorías: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
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

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final precio = double.parse(_priceCtrl.text.replaceAll(',', '.'));
      final cantidad = int.tryParse(_quantityCtrl.text) ?? 1;

      final result = await _productService.createProduct(
        nombre: _titleCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        precioActual: precio,
        categoriaId: _selectedCategoryId!,
        cantidad: cantidad,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        await _showSuccessSheet();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  '¡Producto publicado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu producto ya está disponible en el marketplace',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _formKey.currentState?.reset();
                          _titleCtrl.clear();
                          _descCtrl.clear();
                          _priceCtrl.clear();
                          _quantityCtrl.text = '1';
                          _imageUrlCtrl.clear();
                          setState(() {
                            _selectedCategoryId = null;
                            _previewUrl = null;
                          });
                        },
                        child: const Text('Crear otro'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar modal
                          // ✅ EJECUTAR CALLBACK antes de navegar
                          widget.onProductCreated?.call();
                          context.go('/home');
                        },
                        child: const Text('Ir al inicio'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        backgroundColor: AppColors.azulPrimario,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Preview de imagen
                    Container(
                      height: 200,
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
                                  const Icon(Icons.image_outlined,
                                      size: 48, color: AppColors.grisPrimario),
                                  const SizedBox(height: 12),
                                  const Text('Imagen (próximamente)'),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showComingSoon('Subir imagen'),
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Subir imagen'),
                                  ),
                                ],
                              ),
                            )
                          : Image.network(_previewUrl!, fit: BoxFit.cover),
                    ),

                    const SizedBox(height: 20),

                    // Título
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del producto *',
                        border: OutlineInputBorder(),
                        helperText: 'Mínimo 3 caracteres', // ✅ AGREGADO
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa un título';
                        }
                        if (v.trim().length < 3) {
                          return 'El título debe tener al menos 3 caracteres'; // ✅ MEJORADO
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                        helperText: 'Mínimo 10 caracteres', // ✅ AGREGADO
                      ),
                      maxLines: 4,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa una descripción';
                        }
                        if (v.trim().length < 10) {
                          return 'La descripción debe tener al menos 10 caracteres'; // ✅ MEJORADO
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Precio
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio (CLP) *',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Ingresa un precio';
                        final parsed =
                            double.tryParse(v.replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0)
                          return 'Precio inválido';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Cantidad
                    TextFormField(
                      controller: _quantityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad disponible',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = int.tryParse(v);
                        if (parsed == null || parsed < 1)
                          return 'Cantidad inválida';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Categoría
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría *',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategoryId,
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategoryId = value);
                            },
                            validator: (v) => v == null
                                ? 'Selecciona una categoría'
                                : null,
                          ),

                    const SizedBox(height: 32),

                    // Botón publicar
                    ElevatedButton.icon(
                      onPressed: _createProduct,
                      icon: const Icon(Icons.publish),
                      label: const Text('Publicar producto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppColors.azulPrimario,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}