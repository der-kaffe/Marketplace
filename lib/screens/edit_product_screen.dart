import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';

class EditProductScreen extends StatefulWidget {
  final int productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _productService.getProductById(widget.productId.toString());
      if (product == null) {
        setState(() {
          _errorMessage = 'Producto no encontrado';
          _isLoading = false;
        });
        return;
      }

      _titleCtrl.text = product.title;
      _descCtrl.text = product.description;
      _priceCtrl.text = product.price.toString();
      _quantityCtrl.text = '1'; // Puedes reemplazarlo si tu modelo tiene cantidad

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando producto: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final precio = double.parse(_priceCtrl.text.replaceAll(',', '.'));
      final updated = await _productService.updateProduct(
        productId: widget.productId,
        nombre: _titleCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        precioActual: precio,
      );


      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Producto actualizado correctamente')),
        );
        context.go('/home');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar producto')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar producto'),
        backgroundColor: AppColors.azulPrimario,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El título es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (value == null || value <= 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateProduct,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
