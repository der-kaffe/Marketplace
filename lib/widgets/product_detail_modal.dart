// product_detail_modal.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../theme/app_colors.dart';
import '../screens/seller_profile_page.dart';
import '../screens/chat_page.dart';
import '../services/product_service.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart'; 
import '../services/api_client.dart';

// 🖼️ Widget de visor de imágenes en pantalla completa
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // Construir imagen base64 para pantalla completa
  Widget _buildBase64FullScreenImage(String base64Content) {
    try {
      // Extraer la parte base64 (después de la coma)
      final parts = base64Content.split(',');
      if (parts.length != 2) {
        throw Exception('Formato base64 inválido');
      }
      
      final base64Data = parts[1];
      final bytes = base64Decode(base64Data);
      
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade900,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Error al cargar imagen base64',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${e.toString()}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            onPressed: _resetZoom,
            tooltip: 'Resetear zoom',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _resetZoom(); // Reset zoom al cambiar de imagen
        },        itemBuilder: (context, index) {
          final imageUrl = widget.imageUrls[index];
          final isBase64 = imageUrl.startsWith('data:image');
          
          return Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: isBase64 
                ? _buildBase64FullScreenImage(imageUrl)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey.shade900,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey.shade900,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.imageUrls.length > 1 
          ? Container(
              height: 80,
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: _currentIndex > 0 ? Colors.white : Colors.grey,
                      size: 32,
                    ),
                    onPressed: _currentIndex > 0 
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  // Indicadores de página
                  Row(
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 12 : 8,
                        height: _currentIndex == index ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index 
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _currentIndex < widget.imageUrls.length - 1 
                          ? Colors.white 
                          : Colors.grey,
                      size: 32,
                    ),
                    onPressed: _currentIndex < widget.imageUrls.length - 1 
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class ProductDetailModal extends StatefulWidget {
  final Product product;

  const ProductDetailModal({super.key, required this.product});

  @override
  State<ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<ProductDetailModal> {
  int _userRating = 0;
  final AuthService _authService = AuthService();
  final RatingService _ratingService = RatingService();
  final ProductService _productService = ProductService();
  double _sellerReputation = 0.0;
  bool _isLoadingReputation = true;
  int _cantidadAComprar = 1;
  bool _isComprando = false;

  @override
  void initState() {
    super.initState();
    _loadSellerReputation(); // Cargar reputación del vendedor al iniciar
  }

  // 👇 MÉTODO CORREGIDO
  // Método para cargar la reputación del vendedor (optimizado)
  Future<void> _loadSellerReputation() async {
    setState(() {
      _isLoadingReputation = true;
    });
    try {
      final sellerId = widget.product.sellerId;
      // 1. Llama al servicio que obtiene el perfil del vendedor
      final sellerInfo = await _productService.getSellerInfo(sellerId);

      // 2. Extrae la reputación que ya viene calculada desde el backend
      //    El .toString() y double.tryParse() da robustez si viene como String, num, o Decimal
      final reputationValue = sellerInfo['reputacion']?.toString() ?? '0.0';
      final reputation = double.tryParse(reputationValue) ?? 0.0;

      if (mounted) {
        setState(() {
          _sellerReputation = reputation;
          _isLoadingReputation = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando reputación: $e');
      if (mounted) {
        setState(() {
          _sellerReputation = 0.0;
          _isLoadingReputation = false;
        });
      }
    }
  }

  void _submitRating() async {
    print('🔍 _submitRating - Iniciando proceso de calificación');
    print('   userRating actual: $_userRating');

    if (_userRating <= 0) {
      print('   ❌ Rating no válido: $_userRating');
      return;
    }

    // 🔥 GUARDAR el valor ANTES de hacer CUALQUIER cosa
    final ratingValue = _userRating;

    try {
      final currentUser = await _authService.getCurrentUser();
      print('   currentUser obtenido: ${currentUser != null}');

      if (currentUser == null) {
        print('   ❌ Usuario no autenticado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes iniciar sesión para calificar"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final currentUserId = currentUser['id'];
      final sellerId = int.parse(widget.product.sellerId);

      print('   currentUserId: $currentUserId');
      print('   sellerId: $sellerId');

      if (currentUserId == sellerId) {
        print('   ❌ Usuario intentando calificar a sí mismo');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No puedes calificar tu propio producto"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('   🚀 Enviando calificación al backend...');

      await _ratingService.rateSeller(
        sellerId: sellerId,
        puntuacion: ratingValue, // 🔥 Usar ratingValue en lugar de _userRating
        comentario: "",
      );

      print(
          '   ✅ Calificación enviada exitosamente, actualizando reputación...');

      // Llama a la versión optimizada para refrescar la reputación
      await _loadSellerReputation();

      setState(() {
        _userRating = 0;
      });

      // 🔥 USAR la variable guardada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Gracias por valorar con $ratingValue estrellas!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      print('❌ Error capturado: $errorMessage');
      print('❌ Tipo de error: ${e.runtimeType}');

      // 🔥 ORDEN CORRECTO: Primero verificar códigos de error específicos
      if (errorMessage.contains('ERROR_CODE:NO_TRANSACTION_ERROR') ||
          errorMessage.contains('NO_TRANSACTION_ERROR')) {
        print('   🎯 Detectado: NO_TRANSACTION_ERROR');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Debes haber realizado una transacción con este vendedor para poder calificarlo"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (errorMessage.contains('ERROR_CODE:ALREADY_RATED_TRANSACTION_ERROR') ||
          errorMessage.contains('ALREADY_RATED_TRANSACTION_ERROR')) {
        print('   🎯 Detectado: ALREADY_RATED_TRANSACTION_ERROR');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Ya has calificado esta transacción específica con este vendedor"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verificar usando regex para extraer código de error
      RegExp regExp = RegExp(r'ERROR_CODE:([^:]+):(.+)');
      Match? match = regExp.firstMatch(errorMessage);

      if (match != null) {
        String errorCode = match.group(1) ?? '';
        String actualErrorMessage = match.group(2) ?? errorMessage;

        print('   🔍 Código de error extraído: $errorCode');
        print('   🔍 Mensaje de error: $actualErrorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actualErrorMessage),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 🔥 AHORA SÍ: Verificar errores genéricos (DESPUÉS de los específicos)
      if (errorMessage.contains('sin haber realizado una transacción')) {
        print('   🎯 Detectado por mensaje: sin transacción');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Debes haber realizado una transacción con este vendedor para poder calificarlo"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (errorMessage.contains('ya has calificado')) {
        print('   🎯 Detectado por mensaje: ya calificado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Ya has calificado esta transacción específica con este vendedor"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Error genérico
      print('   ⚠️ Error no identificado, mostrando mensaje genérico');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al enviar calificación: $errorMessage"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _contactSeller() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes iniciar sesión para contactar al vendedor"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final currentUserId = currentUser['id'];
      final sellerId = int.parse(widget.product.sellerId);

      if (currentUserId == sellerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No puedes contactarte a ti mismo"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.pop(context);

      final String avatarUrlOrPath = widget.product.sellerAvatar ?? '../../assets/usuario_sin_foto.jpg';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userName: widget.product.sellerName ?? 'Vendedor',
            avatar: avatarUrlOrPath,
            destinatarioId: sellerId,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error contactando vendedor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al contactar vendedor: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    String reportType = 'producto'; // por defecto

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Reportar"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Selecciona qué deseas reportar:"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'producto',
                            groupValue: reportType,
                            onChanged: (value) {
                              setDialogState(() {
                                reportType = value!;
                              });
                            },
                          ),
                          const Text(
                            "Producto",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'usuario',
                            groupValue: reportType,
                            onChanged: (value) {
                              setDialogState(() {
                                reportType = value!;
                              });
                            },
                          ),
                          const Text(
                            "Usuario",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Motivo del reporte",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Por favor ingresa un motivo.")),
                      );
                      return;
                    }

                    try {
                      if (reportType == 'producto') {
                        final productoId = int.parse(widget.product.id);
                        await ReportService().reportProduct(productoId, reason);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Reporte enviado correctamente para el producto ${widget.product.title}."),
                          ),
                        );
                      } else {
                        final usuarioId = int.parse(widget.product.sellerId);
                        await ReportService().reportUser(usuarioId, reason);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Reporte enviado correctamente para el usuario ${widget.product.sellerName}."),
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Error al enviar el reporte: ${e.toString()}"),
                        ),
                      );
                    }
                  },
                  child: const Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ 2. AÑADE ESTOS MÉTODOS
  //    para controlar el selector de cantidad y el botón de compra.

  /// Incrementa la cantidad a comprar, con un tope máximo del stock.
  void _incrementarCantidad() {
    // Usamos el 'widget.product.cantidad' que asumimos que existe en tu modelo.
    final int stockDisponible = widget.product.cantidad; 

    if (_cantidadAComprar < stockDisponible) {
      setState(() {
        _cantidadAComprar++;
      });
    } else {
      // Si intenta agregar más del stock, muéstrale un aviso.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más unidades disponibles.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Decrementa la cantidad a comprar, con un tope mínimo de 1.
  void _decrementarCantidad() {
    if (_cantidadAComprar > 1) {
      setState(() {
        _cantidadAComprar--;
      });
    }
  }

  // ✅ MODIFICADO: Ahora llama a la API para crear la transacción
  Future<void> _comprarProducto() async { // 👈 Hacerla async
    // Evitar doble click
    if (_isComprando) return;

    setState(() => _isComprando = true);

    print('🛒 Iniciando compra de ${widget.product.title}');
    print('   - Producto ID: ${widget.product.id}');
    print('   - Cantidad seleccionada: $_cantidadAComprar');

    try {
      // Necesitamos el ID como entero
      final productIdInt = int.parse(widget.product.id);

      // Llamamos al servicio (que llama al ApiClient)
      // Asegúrate de tener una instancia de ApiClient o un servicio que lo use.
      // Aquí usamos _productService como ejemplo, pero idealmente tendrías un TransactionService.
      final apiClient = ApiClient(baseUrl: getDefaultBaseUrl()); // O usa tu instancia existente
      final token = await _authService.getToken();
      if (token == null) {
         throw Exception("Debes iniciar sesión para comprar");
      }
      apiClient.setToken(token);

      final result = await apiClient.createTransaction(
        productId: productIdInt,
        quantity: _cantidadAComprar,
      );

      // Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '¡Pedido realizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        // Podrías cerrar el modal o navegar a "Mis Compras"
         Navigator.pop(context); // Cierra el modal después de comprar
      }

    } catch (e) {
      // Error
      print('❌ Error al comprar: $e');
      String errorMessage = 'Ocurrió un error al realizar el pedido.';
      if (e is ApiException) {
        errorMessage = e.message; // Usa el mensaje de error de la API
      } else {
        errorMessage = e.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Asegurarse de quitar el estado de carga
      if (mounted) {
        setState(() => _isComprando = false);
      }
    }
  }

  ///   Este método construye la UI para la sección de compra.
  Widget _buildBuySection() {
    // Asumimos que 'widget.product.cantidad' es el stock
    final int stockDisponible = widget.product.cantidad; 
    final bool estaAgotado = stockDisponible <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fondoClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Mostrar la cantidad disponible
          Text(
            estaAgotado 
              ? 'Producto Agotado' 
              : 'Unidades disponibles: $stockDisponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: estaAgotado ? Colors.red : AppColors.azulOscuro,
            ),
          ),
          
          // Si no está agotado, muestra el selector y el botón
          if (!estaAgotado) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seleccionar cantidad:', style: TextStyle(fontSize: 16)),
                
                // 2. Selector de cantidad (+ / -)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: AppColors.azulPrimario),
                        padding: EdgeInsets.zero,
                        // Deshabilitar si la cantidad es 1
                        onPressed: _cantidadAComprar <= 1 ? null : _decrementarCantidad, 
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '$_cantidadAComprar',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.azulPrimario),
                        padding: EdgeInsets.zero,
                        // Deshabilitar si se alcanza el stock
                        onPressed: _cantidadAComprar >= stockDisponible ? null : _incrementarCantidad, 
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Botón de Comprar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Deshabilitar botón si está cargando
                onPressed: _isComprando ? null : _comprarProducto,
                icon: _isComprando
                    ? Container( // Indicador de carga pequeño
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: AppColors.azulOscuro,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.shopping_cart_checkout),
                label: Text(_isComprando ? 'Procesando...' : 'Comprar Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amarilloPrimario,
                  foregroundColor: AppColors.azulOscuro,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // Cambia el estilo si está deshabilitado
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteProduct() async {
    print('🆔 DEBUG: widget.product = ${widget.product}');
    print('🆔 DEBUG: widget.product.id = ${widget.product.id}');
    if (widget.product == null || widget.product.id == null || widget.product.id.toString().isEmpty) {
      print('❌ El producto o su id es null o vacío');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: El producto no tiene ID válido')),
        );
      }
      return;
    }

    print('🟡 Abriendo diálogo de confirmación...');
    final confirm = await showDialog<bool>(
      context: context, 
      barrierDismissible: false,
      
      // ⬇️ FIX 1: Recibe el 'dialogContext' del builder
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: const Text("¿Seguro que deseas eliminar este producto?"),
        actions: [
          TextButton(
            onPressed: () {
              print('🔴 Cancelar presionado');
              // ⬇️ FIX 2: Usa 'dialogContext'
              Navigator.pop(dialogContext, false); 
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              print('🟢 Eliminar presionado');
              // ⬇️ FIX 3: Usa 'dialogContext'
              Navigator.pop(dialogContext, true); 
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    // ⬇️ Tu otra corrección (que sigue siendo necesaria)
    if (!mounted) return; 

    print('🟣 Valor de confirm: $confirm');
    if (confirm == true) {
      try {
        final productId = int.tryParse(widget.product.id.toString());
        print('🗑️ Eliminando producto con id: $productId');
        
        await _productService.deleteProduct(productId!); 

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto eliminado correctamente')),
          );
          
          await Future.delayed(const Duration(milliseconds: 300)); 

          if (!mounted) return; 
          
          Navigator.of(context).pop(widget.product.id); 
        }
        
        print('✅ Producto eliminado, cerrando modal');
      
      } catch (e) {
        print('❌ Error al eliminar producto: $e');
        if (mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error eliminando producto: $e')),
          );
        }
      }
    } else {
      print('🟠 Eliminación cancelada o diálogo cerrado sin aceptar');
    }
  }

  // 🖼️ Galería de imágenes mejorada para el modal
  Widget _buildModalImage() {
    // Usar múltiples imágenes si están disponibles, sino usar imageUrl individual
    final List<String> imageUrls = widget.product.imagenes?.where((url) => url.isNotEmpty).toList() ?? 
        (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty ? [widget.product.imageUrl!] : []);

    if (imageUrls.isEmpty) {
      return _buildFallbackImage();
    }

    if (imageUrls.length == 1) {
      // Una sola imagen
      return _buildSingleModalImage(imageUrls.first);
    }

    // Múltiples imágenes - carousel con indicadores
    return _buildImageCarousel(imageUrls);
  }
  // 📷 Imagen única en modal
  Widget _buildSingleModalImage(String imageUrl) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),        child: GestureDetector(
          onTap: () => _openFullScreenViewer([imageUrl], 0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 🎠 Carousel de imágenes con indicadores de página
  Widget _buildImageCarousel(List<String> imageUrls) {
    return _ImageCarouselWidget(
      imageUrls: imageUrls,
      onImageTap: (index) => _openFullScreenViewer(imageUrls, index),
    );
  }

  // 📱 Abrir visor de pantalla completa
  void _openFullScreenViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // 🖼️ Imagen por defecto cuando no hay imágenes
  Widget _buildFallbackImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Image.asset(
        'assets/producto_sin_foto.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildModalImage(),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulPrimario,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${widget.product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descripción del producto
                Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 16),
                ),
                
                // 👇 Nueva sección: Información adicional del producto
                if (widget.product.estadoProducto != null || 
                    widget.product.tiempoUso != null || 
                    widget.product.informacionTecnica != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Información del producto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulPrimario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Estado del producto y tiempo de uso en fila
                  if (widget.product.estadoProducto != null || widget.product.tiempoUso != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (widget.product.estadoProducto != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.product.estadoProducto == 'nuevo' 
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.product.estadoProducto == 'nuevo' 
                                    ? Colors.green
                                    : Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.product.estadoProducto == 'nuevo' 
                                      ? Icons.check_circle
                                      : Icons.sell,
                                  size: 18,
                                  color: widget.product.estadoProducto == 'nuevo' 
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.product.estadoProducto == 'nuevo' ? 'Nuevo' : 'Usado',
                                  style: TextStyle(
                                    color: widget.product.estadoProducto == 'nuevo' 
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.product.tiempoUso != null && widget.product.tiempoUso!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  widget.product.tiempoUso!,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  
                  // Información técnica
                  if (widget.product.informacionTecnica != null && 
                      widget.product.informacionTecnica!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, 
                                size: 20, 
                                color: AppColors.azulPrimario),
                              const SizedBox(width: 8),
                              const Text(
                                'Información técnica',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.informacionTecnica!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                ],
                
                const SizedBox(height: 16),

                // ✅ 3. AÑADE TU NUEVA SECCIÓN AQUÍ
                const SizedBox(height: 24), // Un buen espacio
                _buildBuySection(),
                const SizedBox(height: 16),
                // ------------------------------------

                // Sección de reputación del vendedor
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reputación del vendedor:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingReputation)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Cargando reputación..."),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: _sellerReputation > 0
                                  ? Colors.amber.shade700
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sellerReputation > 0
                                  ? "${_sellerReputation.toStringAsFixed(1)}/5.0"
                                  : "Sin calificaciones",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sección de calificación del usuario
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tu valoración:",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            index < _userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _userRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    if (_userRating > 0)
                      Text("Seleccionaste: $_userRating estrellas",
                          style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _userRating > 0 ? _submitRating : null,
                        child: const Text("Enviar valoración"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black45,
                    ),
                    icon: CircleAvatar(
                      radius: 20,
                      // Lógica para decidir qué tipo de imagen mostrar
                      backgroundImage: (widget.product.sellerAvatar != null && widget.product.sellerAvatar!.startsWith('http'))
                          // Si el avatar es una URL, usa NetworkImage
                          ? NetworkImage(widget.product.sellerAvatar!)
                          // Si no, usa el Asset local
                          : const AssetImage('assets/usuario_sin_foto.jpg') as ImageProvider,
                      // Fallback por si la carga de NetworkImage falla (opcional pero recomendado)
                      onBackgroundImageError: (_, __) {
                        // Puedes dejar esto vacío o loggear un error
                      },
                      child: (widget.product.sellerAvatar != null && widget.product.sellerAvatar!.startsWith('http'))
                          ? null // Si es NetworkImage, no necesita child
                          // Si es AssetImage, el child se muestra si onBackgroundImageError falla
                          : const Icon(Icons.person, size: 20), // Fallback de Icono
                    ),
                    label: Text(
                      "Ver perfil del vendedor: ${widget.product.sellerName ?? 'Desconocido'}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final seller = ProductService()
                          .getSellerInfo(widget.product.sellerId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FutureBuilder<Map<String, dynamic>>(
                            future: seller,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Scaffold(
                                  appBar: AppBar(
                                      title: const Text('Perfil del Vendedor')),
                                  body: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (snapshot.hasError || !snapshot.hasData) {
                                return Scaffold(
                                  appBar: AppBar(
                                      title: const Text('Perfil del Vendedor')),
                                  body: Center(
                                    child: Text(
                                        'Error cargando perfil: ${snapshot.error}'),
                                  ),
                                );
                              }                              // ✅ CORREGIDO: Mapear correctamente a los campos del modelo Seller existente
                              final sellerData = snapshot.data!;
                              print('🔍 Datos del vendedor recibidos: $sellerData'); // Debug
                              // ✅ Extraer estadísticas correctamente desde el objeto 'estadisticas'
                              final estadisticas = sellerData['estadisticas'] ?? {};
                              print('📊 Estadísticas extraídas: $estadisticas'); // Debug
                              print('📊 publicacionesActivas: ${estadisticas['publicacionesActivas']}'); // Debug
                              print('📊 tipo publicacionesActivas: ${estadisticas['publicacionesActivas'].runtimeType}'); // Debug
                              
                              final activeListingsValue = (estadisticas['publicacionesActivas'] as num?)?.toInt() ?? 0;
                              print('📊 activeListingsValue después de conversión: $activeListingsValue'); // Debug
                              
                              final sellerObject = Seller(
                                id: sellerData['id']?.toString() ??
                                    widget.product.sellerId,
                                name: sellerData['name'] ?? sellerData['nombre'] ?? 'Vendedor',
                                email: sellerData['correo'] ?? sellerData['email'],
                                avatar: sellerData['avatar'] ?? sellerData['fotoPerfilUrl'],
                                location: sellerData['campus'] ?? 'Desconocido',                                reputation: (sellerData['reputacion'] is num) 
                                    ? (sellerData['reputacion'] as num).toDouble() 
                                    : 0.0,
                                // ✅ USAR ESTADÍSTICAS REALES del backend con conversión segura
                                totalSales: (estadisticas['totalVentas'] as num?)?.toInt() ?? 0,
                                activeListings: activeListingsValue,
                                soldListings: (estadisticas['totalVentas'] as num?)?.toInt() ?? 0,
                                memberSince: sellerData['miembroDesde'] != null 
                                    ? DateTime.tryParse(sellerData['miembroDesde'].toString()) 
                                    : null,
                              );
                              
                              print('✅ Objeto Seller creado - Activas: ${sellerObject.activeListings}, Ventas: ${sellerObject.totalSales}'); // Debug

                              return SellerProfilePage(seller: sellerObject);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _contactSeller,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      "Contactar vendedor",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text(
                      "Reportar",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _showReportDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                FutureBuilder<Map<String, dynamic>?>(
                  future: _authService.getCurrentUser(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final currentUser = snapshot.data;
                    final isMyProduct =
                        currentUser != null &&
                        currentUser['id'].toString() == widget.product.sellerId;

                    if (!isMyProduct) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                // Navegar a pantalla de edición usando el id en la URL
                                context.push('/edit_product/${widget.product.id}');
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                            ),
                            ElevatedButton.icon(
                                onPressed: _confirmAndDeleteProduct,
                                icon: const Icon(Icons.delete),
                                label: const Text('Eliminar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🎠 Widget separado para el carousel de imágenes con estado propio
class _ImageCarouselWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(int)? onImageTap;

  const _ImageCarouselWidget({
    required this.imageUrls,
    this.onImageTap,
  });

  @override
  State<_ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<_ImageCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Image.asset(
        'assets/producto_sin_foto.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          // Carousel de imágenes
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (widget.onImageTap != null) {
                      widget.onImageTap!(index);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(
                            imageUrls: widget.imageUrls,
                            initialIndex: index,
                          ),
                        ),
                      );
                    }
                  },
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Indicadores de página (dots)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index 
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Contador de imágenes
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Botones de navegación (opcional, para mejor UX)
          if (widget.imageUrls.length > 1) ...[
            // Botón anterior
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _currentIndex > 0 ? Colors.white : Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            // Botón siguiente
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex < widget.imageUrls.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentIndex < widget.imageUrls.length - 1 ? Colors.white : Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
