import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  final _priceCtrl = TextEditingController();  final _quantityCtrl = TextEditingController();
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // 🖼️ Gestión de imágenes
  List<String> _existingImageUrls = []; // URLs de imágenes existentes del servidor
  List<File> _newImageFiles = []; // Nuevas imágenes seleccionadas localmente
  bool _isUploadingImage = false;
  final int _maxImages = 5;

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
      
      // Cargar imágenes existentes
      if (product.imagenes != null && product.imagenes!.isNotEmpty) {
        _existingImageUrls = List<String>.from(product.imagenes!);
      } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        _existingImageUrls = [product.imageUrl!];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando producto: $e';
        _isLoading = false;
      });
    }
  }
  // 🖼️ Seleccionar múltiples imágenes nuevas
  Future<void> _pickImages() async {
    if (_isSaving || _isUploadingImage) return;
    
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFiles.isNotEmpty) {
        final totalImages = _existingImageUrls.length + _newImageFiles.length + pickedFiles.length;
        
        if (totalImages > _maxImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Máximo $_maxImages imágenes por producto'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _newImageFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🗑️ Remover imagen existente
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  // 🗑️ Remover imagen nueva
  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  // 📤 Subir imagen a base64
  Future<String?> _uploadImage(File imageFile) async {
    setState(() => _isUploadingImage = true);
    String? imageDataBase64;
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }
      
      imageDataBase64 = 'data:$mimeType;base64,$base64Image';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
    return imageDataBase64;
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que haya al menos una imagen
    if (_existingImageUrls.isEmpty && _newImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tener al menos una imagen')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final precio = double.parse(_priceCtrl.text.replaceAll(',', '.'));
        // Combinar imágenes existentes con nuevas imágenes convertidas a base64
      List<String> allImages = List<String>.from(_existingImageUrls);
      
      print('📊 Imágenes existentes: ${_existingImageUrls.length}');
      for (var i = 0; i < _existingImageUrls.length; i++) {
        print('📊 Imagen existente $i: ${_existingImageUrls[i].substring(0, 50)}...');
      }
      
      // Convertir nuevas imágenes a base64
      for (File imageFile in _newImageFiles) {
        final imageDataBase64 = await _uploadImage(imageFile);
        if (imageDataBase64 != null) {
          allImages.add(imageDataBase64);
          print('📊 Nueva imagen agregada: ${imageDataBase64.substring(0, 50)}...');
        }
      }
      
      print('📊 Total de imágenes a enviar: ${allImages.length}');
      
      if (allImages.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error procesando las imágenes')),
        );
        return;
      }

      await _productService.updateProductWithImages(
        productId: widget.productId,
        nombre: _titleCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        precioActual: precio,
        imagenes: allImages,
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
        padding: const EdgeInsets.all(16.0),        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🖼️ Galería de imágenes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Imágenes * (${_existingImageUrls.length + _newImageFiles.length}/$_maxImages)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_existingImageUrls.length + _newImageFiles.length < _maxImages)
                        TextButton.icon(
                          onPressed: _isUploadingImage || _isSaving ? null : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Agregar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Mostrar imágenes existentes y nuevas
                  (_existingImageUrls.isEmpty && _newImageFiles.isEmpty)
                      ? Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grisClaro, width: 2),
                            color: Colors.grey.shade50,
                          ),
                          child: InkWell(
                            onTap: _isUploadingImage || _isSaving ? null : _pickImages,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48, color: AppColors.grisPrimario),
                                SizedBox(height: 8),
                                Text(
                                  'Toca para agregar imágenes',
                                  style: TextStyle(color: AppColors.grisPrimario),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length + _newImageFiles.length,
                            itemBuilder: (context, index) {
                              final isExisting = index < _existingImageUrls.length;
                              
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.grisClaro),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: isExisting
                                          ? Image.network(
                                              _existingImageUrls[index],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image, size: 40),
                                                );
                                              },
                                            )
                                          : Image.file(
                                              _newImageFiles[index - _existingImageUrls.length],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (isExisting) {
                                            _removeExistingImage(index);
                                          } else {
                                            _removeNewImage(index - _existingImageUrls.length);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isExisting)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'NUEVA',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 20),
              
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
