import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';

class ProductDetailModal extends StatelessWidget {
  final Product product;

  const ProductDetailModal({super.key, required this.product});

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
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl ?? "https://via.placeholder.com/300",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulPrimario,
                  ),
                ),

                const SizedBox(height: 8),

                // Precio
                Text(
                  "\$${product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),

                const SizedBox(height: 16),

                // Descripción
                Text(
                  product.description,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 16),

                // Rating y reseñas
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 4),
                    Text("${product.rating} (${product.reviewCount} reseñas)"),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón de contactar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // 🚀 Aquí luego integran mensajería real
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Próximamente: contactar vendedor"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      "Contactar vendedor",
                      style: TextStyle(fontSize: 16),
                    ),
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
