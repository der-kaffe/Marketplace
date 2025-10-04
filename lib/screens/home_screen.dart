import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../widgets/product_detail_modal.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  final List<Product> _products = [];
  bool _isLoading = false;
  int _page = 0;
  final int _limit = 4; // productos por carga (matching original count)

  // ✅ AGREGADO: Set para trackear favoritos
  final Set<String> _favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadMore();
    _loadFavorites(); // ✅ AGREGADO


    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMore();
      }
    });  }

  // ✅ AGREGADO: Cargar favoritos del usuario
  Future<void> _loadFavorites() async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _authService.apiClient.setToken(token);
      }

      final resp = await _authService.apiClient.getProductFavorites(page: 1, limit: 100);
      setState(() {
        _favoriteProductIds.clear();
        for (var fav in resp.favorites) {
          _favoriteProductIds.add(fav.productoId.toString());
        }
      });
    } catch (e) {
      // Manejo de errores opcional
      print('Error al cargar favoritos: $e');
    }
  }

  // ✅ AGREGADO: Toggle favorito
  Future<void> _toggleFavorite(Product product) async {
    try {
      final productId = int.parse(product.id);
      final isFavorite = _favoriteProductIds.contains(product.id);

      if (isFavorite) {
        // Eliminar de favoritos
        await _authService.apiClient.removeProductFavorite(productoId: productId);
        setState(() {
          _favoriteProductIds.remove(product.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eliminado de favoritos')),
          );
        }
      } else {
        // Agregar a favoritos
        await _authService.apiClient.addProductFavorite(productoId: productId);
        setState(() {
          _favoriteProductIds.add(product.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregado a favoritos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


  // Método para asignar colores a las categorías dinámicamente
  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,                      // Vehículos
      AppColors.azulPrimario,          // Inmuebles  
      AppColors.amarilloPrimario,      // Electrónica
      Colors.green,                    // Hogar y jardín
      Colors.orange,                   // Moda y accesorios
      Colors.pink,                     // Bebés y niños
      Colors.red,                      // Juguetes y juegos
      Colors.brown,                    // Herramientas
      Colors.blue,                     // Deportes y ocio
      Colors.purple,                   // Mascotas
      Colors.purple,                   // Joyas
      Colors.pink,                     // Belleza
      Colors.teal,                     // Servicios
      Colors.indigo,                   // Alquileres
    ];
    return colors[index % colors.length];
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final newProducts =
        await _productService.fetchProducts(page: _page, limit: _limit);
        
    setState(() {
      _products.addAll(newProducts);
      _page++;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 si estamos cargando y aún no hay productos → muestra solo el loader
    if (_isLoading && _products.isEmpty) {
      return const Scaffold(
        body: Center(
          child: SpinKitWave(
            color: AppColors.azulPrimario,
            size: 50.0,
          ),
        ),
      );
    }

    // 👇 de lo contrario, muestra el contenido normal
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de bienvenida con gradiente
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.azulPrimario, AppColors.azulPrimario.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulPrimario.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido al MicroMarket!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descubre productos increíbles de la comunidad UCT',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Categorías
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulPrimario,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Lista horizontal de categorías (dinámico desde el servicio)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _productService.getAllCategories().length,
                      itemBuilder: (context, index) {
                        final category = _productService.getAllCategories()[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 16 : 8,
                            right: index == _productService.getAllCategories().length - 1 ? 16 : 0,
                          ),
                          child: CategoryCard(
                            icon: ProductService.getIconForName(category.iconName ?? 'category'), // 🔧 Manejar null
                            title: category.name,
                            color: _getCategoryColor(index),
                            onTap: () => _showNotImplementedMessage(context, 'Categoría: ${category.name}'),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Productos destacados con card mejorada
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.amarilloPrimario.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: AppColors.amarilloPrimario,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Productos destacados',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulPrimario,
                              ),
                            ),
                          ],
                        ),              
                        const SizedBox(height: 20),
                        
                        // Productos destacados en grid con infinite scroll
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _products.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return const Center(
                                child: SpinKitFadingCircle(
                                  color: AppColors.azulPrimario,
                                  size: 40.0,
                                ),
                              );
                            }
                            
                            final product = _products[index];
                            final isFavorite = _favoriteProductIds.contains(product.id); // ✅ AGREGADO

                            return ProductCard(
                              title: product.title,
                              description: product.description,
                              price: product.price,
                              imageUrl: product.imageUrl,
                              isFavorite: isFavorite, // ✅ AGREGADO
                              isAvailable: product.isAvailable,
                              onToggleVisibility: () {
                                setState(() {
                                  _products[index] = product.copyWith(isAvailable: !product.isAvailable);
                                });
                              },
                              onToggleFavorite: () { // ✅ AGREGADO
                                _toggleFavorite(product);
                              },
                              onTap: () {
                                // Solo se abre el modal cuando se presiona la tarjeta (no los botones)
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ProductDetailModal(product: product),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar mensaje cuando una función aún no está implementada
  void _showNotImplementedMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.azulPrimario,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}