import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../widgets/product_detail_modal.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _authService = AuthService();
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  bool _isRefreshing = false;

  List<FavoritedProduct> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _authService.apiClient.setToken(token);
      }

      final resp = await _authService.apiClient.getProductFavorites(page: 1, limit: 50);
      setState(() {
        _favorites = resp.favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar favoritos: $e')),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _loadFavorites();
    setState(() => _isRefreshing = false);
  }

  Future<void> _removeFavorite(int productoId) async {
    try {
      await _authService.apiClient.removeProductFavorite(productoId: productoId);
      setState(() {
        _favorites.removeWhere((f) => f.productoId == productoId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eliminado de favoritos')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      body: _isLoading
          ? Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 50.0,
              ),
            )
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final fav = _favorites[index];
                      return _buildFavoriteCard(fav);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: AppColors.grisPrimario),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos aún',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.azulPrimario,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos a favoritos para verlos aquí',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(FavoritedProduct fav) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.grisPrimario.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: AppColors.azulPrimario),
        ),
        title: Text(
          fav.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (fav.categoria != null) fav.categoria!,
            if (fav.precioActual != null) '\$${fav.precioActual!.toStringAsFixed(0)}',
            if (fav.vendedorNombre.isNotEmpty) fav.vendedorNombre,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'Quitar de favoritos',
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _removeFavorite(fav.productoId),
        ),
        onTap: () async {
          // 1. Crear una variable nullable para el contexto del diálogo
          BuildContext? dialogContext;

          // 2. Mostrar un indicador de carga
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext bContext) { // <-- 3. Capturar el contexto del builder
              dialogContext = bContext; // <-- 4. Asignarlo a nuestra variable
              return const Center(
                child: CircularProgressIndicator(color: AppColors.azulPrimario),
              );
            },
          );

          Product? product;
          dynamic apiError;

          // 5. Intentar obtener los datos del producto
          try {
            product = await _productService.getProductById(fav.productoId.toString());
          } catch (e) {
            apiError = e;
          }

          if (!mounted) return;

          // 6. CERRAR el diálogo de carga USANDO SU PROPIO CONTEXTO
          if (dialogContext != null) {
            Navigator.pop(dialogContext!); // <-- ✅ ¡LA CORRECCIÓN CLAVE!
          } else {
            // Fallback por si algo muy raro pasa (casi nunca se usará)
            Navigator.pop(context);
          }

          // 7. ESPERAR un instante para que el Navigator se asiente
          await Future.delayed(const Duration(milliseconds: 50));
          if (!mounted) return;

          // 8. AHORA, decidir qué hacer (mostrar modal o mostrar error)
          if (product != null) {
            // 9. ¡Éxito! Mostrar el modal de detalles
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ProductDetailModal(
                product: product!.copyWith(
                  isFavorite: true,
                ),
              ),
            );
          } else {
            // 10. Error: Mostrar el error de la API
            final errorMessage = apiError is ApiException
                ? apiError.message
                : (apiError?.toString() ?? 'Error desconocido');
                
            print('❌ Error al buscar producto por ID: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar detalles: $errorMessage'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}