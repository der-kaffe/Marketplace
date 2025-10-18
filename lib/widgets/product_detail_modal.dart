// product_detail_modal.dart

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
import '../services/rating_service.dart'; // Añadido

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
  final ProductService _productService =
      ProductService(); // ✅ Instancia del servicio
  double _sellerReputation = 0.0;
  bool _isLoadingReputation = true;

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userName: widget.product.sellerName ?? 'Vendedor',
            avatar: widget.product.sellerAvatar ??
                'https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg',
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

  Widget _buildModalImage() {
    if (widget.product.imageUrl == null || widget.product.imageUrl!.isEmpty) {
      return Image.asset(
        'assets/producto_sin_foto.jpg',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    return Image.network(
      widget.product.imageUrl!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/producto_sin_foto.jpg',
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
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
                Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

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
                      backgroundImage: NetworkImage(
                        widget.product.sellerAvatar ??
                            "https://via.placeholder.com/150",
                      ),
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
                              }

                              // ✅ CORREGIDO: Mapear correctamente a los campos del modelo Seller existente
                              final sellerData = snapshot.data!;
                              final sellerObject = Seller(
                                id: sellerData['id']?.toString() ??
                                    widget.product.sellerId, // ✅ AGREGADO
                                name: sellerData['nombre'] ??
                                    sellerData['name'] ??
                                    'Vendedor',
                                email: sellerData['correo'] ??
                                    sellerData['email'] ??
                                    '',
                                avatar: sellerData['avatar'],
                                location: sellerData['campus'] ?? 'Desconocido',
                                reputation:
                                    sellerData['reputacion']?.toDouble() ?? 0.0,
                                totalSales: 0, // ✅ Por ahora, valor por defecto
                                activeListings:
                                    0, // ✅ Por ahora, valor por defecto
                                soldListings:
                                    0, // ✅ Por ahora, valor por defecto
                              );

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
              ],
            ),
          ),
        );
      },
    );
  }
}
