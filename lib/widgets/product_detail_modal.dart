import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../theme/app_colors.dart';
import '../screens/seller_profile_page.dart';
import '../screens/chat_page.dart';
import '../services/product_service.dart';
import '../services/report_service.dart'; // ✅ Import del nuevo servicio
import '../services/auth_service.dart';

class ProductDetailModal extends StatefulWidget {
  final Product product;

  const ProductDetailModal({super.key, required this.product});

  @override
  State<ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<ProductDetailModal> {
  int _userRating = 0;
  final AuthService _authService = AuthService();

  void _submitRating() {
    if (_userRating > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Gracias por valorar con $_userRating estrellas!"),
        ),
      );
    }
  }

  // 💬 Contactar vendedor - abrir chat
  Future<void> _contactSeller() async {
    try {
      // Verificar que el usuario esté logueado
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

      // Verificar que no sea el mismo usuario
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

      // Cerrar el modal y abrir el chat
      Navigator.pop(context); // Cerrar el modal del producto
      
      // Abrir el chat con el vendedor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userName: widget.product.sellerName ?? 'Vendedor',
            avatar: widget.product.sellerAvatar ?? 'https://thumbs.dreamstime.com/b/vector-de-perfil-avatar-predeterminado-foto-usuario-medios-sociales-icono-183042379.jpg',
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

  // ✅ Mostrar diálogo para reportar producto (ahora con backend real)
  void _showReportDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reportar producto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Por favor, indica el motivo del reporte:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      "Ejemplo: Contenido inapropiado o información falsa",
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
                  final productoId = int.parse(widget.product.id);
                  // ✅ Llamada real al servicio
                  await ReportService().reportProduct(productoId, reason);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Reporte enviado correctamente para el producto ${productoId}.",
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Error al enviar el reporte: ${e.toString()}"),
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
  }

  // ✅ Imagen con fallback
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
                // ✅ Imagen del producto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildModalImage(),
                ),
                const SizedBox(height: 16),

                // 🏷️ Título
                Text(
                  widget.product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulPrimario,
                  ),
                ),
                const SizedBox(height: 8),

                // 💲 Precio
                Text(
                  "\$${widget.product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 16),

                // 📝 Descripción
                Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // ⭐ Promedio y reseñas
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${widget.product.rating} (${widget.product.reviewCount} reseñas)",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ⭐ Valoración interactiva
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

                // 👤 Ver perfil del vendedor
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
                              SellerProfilePage(seller: seller),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 💬 Contactar vendedor
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

                // 🛑 Reportar producto
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
                      "Reportar producto",
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
