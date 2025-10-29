import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool isAvailable;
  final VoidCallback? onToggleVisibility;
  final VoidCallback onToggleFavorite;
  // 👇 Nuevos campos
  final String? estadoProducto; // 'nuevo' o 'usado'
  final String? tiempoUso;

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
    required this.onToggleFavorite,
    this.estadoProducto,
    this.tiempoUso,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // ✅ Mantener el tamaño de imagen que prefieres
      final imageHeight = constraints.maxWidth * 0.7; // VOLVEMOS al tamaño anterior
      
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
              // ✅ Imagen con altura que prefieres
              SizedBox(
                height: imageHeight,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: imageHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: _buildImage(),
                      ),
                    ),
                    
                    // ✅ Botón de visibilidad (arriba a la izquierda)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: onToggleVisibility,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isAvailable ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    // ✅ Botón de favoritos (arriba a la derecha)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ SOLUCIÓN DEFINITIVA: Usar Expanded para tomar todo el espacio restante
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Título que se adapta al espacio disponible
                      Flexible(
                        flex: 3, // 3 partes del espacio disponible
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // ✅ Descripción que se adapta al espacio disponible
                      Flexible(
                        flex: 2, // 2 partes del espacio disponible
                        child: Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            height: 1.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // 👇 Nuevos campos: Estado y tiempo de uso
                      if (estadoProducto != null || tiempoUso != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (estadoProducto != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: estadoProducto == 'nuevo' 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: estadoProducto == 'nuevo' 
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  estadoProducto == 'nuevo' ? 'Nuevo' : 'Usado',
                                  style: TextStyle(
                                    color: estadoProducto == 'nuevo' 
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (tiempoUso != null && tiempoUso!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 10, color: Colors.blue.shade700),
                                    const SizedBox(width: 2),
                                    Text(
                                      tiempoUso!,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      
                      // ✅ Espaciador flexible
                      const Spacer(),
                      
                      // ✅ Precio que siempre se muestra completo
                      Text(
                        _formatCLP(price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.azulPrimario,
                        ),
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

  // Devuelve una URL absoluta válida para el emulador Android
  String _getAbsoluteImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    } else if (url.startsWith('/uploads/')) {
      // Cambia aquí la IP si usas otro backend o emulador
      return 'http://10.0.2.2:3001$url';
    }
    return url; // fallback
  }

  // ✅ Método para construir la imagen con fallback a asset
  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      // Si no hay URL, mostrar imagen por defecto desde assets
      return Image.asset(
        'assets/producto_sin_foto.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image,
              size: 35,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    // Si hay URL, asegurar que sea absoluta
    final String displayUrl = _getAbsoluteImageUrl(imageUrl!);

    // Cargar de la red con fallback a asset
    return Image.network(
      displayUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Si falla la carga de red, mostrar imagen por defecto
        return Image.asset(
          'assets/producto_sin_foto.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.image,
                size: 35,
                color: Colors.grey,
              ),
            );
          },
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
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

  String _formatCLP(num value) {
    final format = NumberFormat.currency(locale: 'es_CL', symbol: ' ', decimalDigits: 0);
    // Elimina el espacio y el símbolo CLP si lo agrega
    return format.format(value).replaceAll('CLP', '').replaceAll(' ', '').trim();
  }
}