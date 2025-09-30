import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool isAvailable;
  final VoidCallback onToggleVisibility;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.onTap,
    this.isFavorite = false,
    required this.isAvailable,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con botón de visibilidad
              Stack(
                children: [
                  Container(
                    height: constraints.maxHeight * 0.45, // 45% de la altura
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grisPrimario.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.grisPrimario,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: AppColors.grisPrimario,
                              size: 40,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        isAvailable ? Icons.visibility : Icons.visibility_off,
                        color: isAvailable
                            ? AppColors.azulPrimario
                            : AppColors.grisPrimario,
                      ),
                      onPressed: onToggleVisibility,
                    ),
                  ),
                ],
              ),

              // Sección de detalles
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulPrimario,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textoSecundario,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.grisPrimario,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
