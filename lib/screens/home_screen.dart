// lib/screens/home_screen.dart (actualizado con solución de duplicados)

import 'package:flutter/material.dart';
import '../models/product_model.dart' as ProductModel;
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../widgets/product_detail_modal.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  final List<Product> _allProducts =
      []; // Almacena *todos* los productos cargados (puede acumular duplicados si se recarga mal)
  final List<Product> _originalProducts =
      []; // Almacena *una sola vez* los productos iniciales, limpia de duplicados
  List<Product> _filteredProducts =
      []; // Almacena los productos *filtrados* o la copia de _originalProducts
  List<ProductModel.ApiCategory> _apiCategories = [];
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = true;
  String? _errorCategories;
  int _page = 1;
  final int _limit = 4;
  final Set<String> _favoriteProductIds = {};

  String? _selectedCategoryName;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadMoreProducts(); // Carga productos iniciales
    _loadFavorites();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingProducts &&
          _selectedCategoryName == null) {
        // No cargar más si hay un filtro activo
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorCategories = null;
    });

    try {
      final categories = await _authService.apiClient.getCategoriesFromApi();
      setState(() {
        _apiCategories = categories;
        _isLoadingCategories = false;
      });
      print('✅ Categorías cargadas desde API: ${categories.length}');
    } catch (e) {
      setState(() {
        _errorCategories = e.toString();
        _isLoadingCategories = false;
      });
      print('❌ Error cargando categorías desde API: $_errorCategories');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error cargando categorías: $_errorCategories')),
        );
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _authService.apiClient.setToken(token);
      }

      final resp =
          await _authService.apiClient.getProductFavorites(page: 1, limit: 100);
      setState(() {
        _favoriteProductIds.clear();
        for (var fav in resp.favorites) {
          _favoriteProductIds.add(fav.productoId.toString());
        }
      });
    } catch (e) {
      print('Error al cargar favoritos: $e');
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    try {
      final productId = int.parse(product.id);
      final isFavorite = _favoriteProductIds.contains(product.id);

      if (isFavorite) {
        await _authService.apiClient
            .removeProductFavorite(productoId: productId);
        setState(() {
          _favoriteProductIds.remove(product.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eliminado de favoritos')),
          );
        }
      } else {
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

  // Método para cargar productos (simula paginación)
  Future<void> _loadMoreProducts() async {
    if (_isLoadingProducts || _selectedCategoryName != null)
      return; // No cargar si hay filtro activo o ya está cargando

    setState(() => _isLoadingProducts = true);

    try {
      final newProducts = await _productService.fetchProducts(
        page: _page,
        limit: _limit,
      );

      setState(() {
        // Lógica para poblar _allProducts y _originalProducts
        if (_allProducts.isEmpty && _originalProducts.isEmpty) {
          // Primera carga: poblar ambas listas
          _allProducts.addAll(newProducts);
          _originalProducts
              .addAll(newProducts); // Guardar copia limpia original
          _filteredProducts =
              List.from(_originalProducts); // Mostrar originales
        } else if (_allProducts.isNotEmpty && _originalProducts.isNotEmpty) {
          // Carga paginada: añadir solo a _allProducts
          _allProducts.addAll(newProducts);
          // Si NO hay filtro activo, también añadir a _filteredProducts
          if (_selectedCategoryName == null) {
            _filteredProducts.addAll(newProducts);
          }
        }
        _page++;
      });

      print(
          '✅ Productos cargados: ${newProducts.length} (total _allProducts: ${_allProducts.length}, total _originalProducts: ${_originalProducts.length})');
    } catch (e) {
      print('❌ Error cargando productos: $e');
      setState(() => _isLoadingProducts = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando productos: $e')),
        );
      }
    }
  }

  // --- NUEVO: Función auxiliar corregida para obtener nombres de subcategorías ---
  Set<String> _getAllSubcategoryNames(
      int parentId, List<ProductModel.ApiCategory> allCategories) {
    Set<String> names = {};

    void _exploreSubcategories(ProductModel.ApiCategory category) {
      names.add(category.nombre);
      for (var subCat in category.subcategorias) {
        _exploreSubcategories(subCat);
      }
    }

    ProductModel.ApiCategory? parentCat = allCategories.firstWhere(
      (cat) => cat.id == parentId,
      orElse: () =>
          ProductModel.ApiCategory(id: -1, nombre: '', subcategorias: []),
    );

    if (parentCat.id != -1) {
      _exploreSubcategories(parentCat);
    }

    return names;
  }
  // --- FIN NUEVO ---

  // --- ACTUALIZADO: Método de filtro para usar _originalProducts ---
  void _filterProductsByCategory(int? categoryId, String? categoryName) {
    print('--- DEBUG _filterProductsByCategory ---');
    print('Categoría seleccionada: $categoryName (ID: $categoryId)');
    print('---------------------------------------');

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;

      if (categoryId == null) {
        // Limpiar filtro: restaurar desde la lista original limpia
        _filteredProducts =
            List.from(_originalProducts); // ✅ Usa la copia original
        print(
            'Filtro limpiado. Mostrando ${_filteredProducts.length} productos originales.');
      } else {
        // Obtener el conjunto de NOMBRES de categorías que incluye la categoría seleccionada y todas sus subcategorías
        Set<String> categoryNamesToFilter =
            _getAllSubcategoryNames(categoryId, _apiCategories);
        print(
            'Nombres de categorías a filtrar (padre + hijos): $categoryNamesToFilter');

        // Filtrar productos cuyo category (nombre como string) esté en ese conjunto de nombres
        // ✅ Filtra desde la lista original
        _filteredProducts = _originalProducts.where((product) {
          bool matches = categoryNamesToFilter.contains(product.category);
          print(
              'Producto: ${product.title}, Category String: "${product.category}", Matches: $matches');
          return matches;
        }).toList();

        print(
            'Productos filtrados: ${_filteredProducts.length} de ${_originalProducts.length} originales');
      }
      _page = 1; // Reiniciar página si se aplica un filtro
    });
    print(
        '🔍 Filtrando por categoría: $categoryName (ID: $categoryId) y sus subcategorías (por nombre). Productos filtrados: ${_filteredProducts.length}');
  }
  // --- FIN ACTUALIZADO ---

  void _clearCategoryFilter() {
    _filterProductsByCategory(null, null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProducts && _originalProducts.isEmpty) {
      // Cambiado a _originalProducts
      return const Scaffold(
        body: Center(
          child: SpinKitWave(
            color: AppColors.azulPrimario,
            size: 50.0,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.azulPrimario,
                    AppColors.azulPrimario.withValues(alpha: 0.8)
                  ],
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
                  if (!_isLoadingCategories && _apiCategories.isNotEmpty) ...[
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulPrimario,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _apiCategories.length,
                        itemBuilder: (context, index) {
                          final category = _apiCategories[index];
                          Color color = _getCategoryColor(index);
                          String title = category.nombre;
                          IconData icon =
                              ProductService.getIconForName('category');

                          return Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 16 : 8,
                              right:
                                  index == _apiCategories.length - 1 ? 16 : 0,
                            ),
                            child: CategoryCard(
                              icon: icon,
                              title: title,
                              color: color,
                              onTap: () {
                                _filterProductsByCategory(
                                    category.id, category.nombre);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_isLoadingCategories) ...[
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulPrimario,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                  ] else if (_errorCategories != null) ...[
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulPrimario,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text('Error al cargar categorías: $_errorCategories'),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_apiCategories.isEmpty) ...[
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulPrimario,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: Text('No hay categorías disponibles.')),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedCategoryName != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.azulPrimario.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Filtrando por: '),
                          Text(
                            '$_selectedCategoryName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearCategoryFilter,
                          ),
                        ],
                      ),
                    ),
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
                                color: AppColors.amarilloPrimario
                                    .withValues(alpha: 0.1),
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
                              'Productos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulPrimario,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length +
                              (_isLoadingProducts &&
                                      _selectedCategoryName == null
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredProducts.length) {
                              if (_isLoadingProducts &&
                                  _selectedCategoryName == null) {
                                return const Center(
                                  child: SpinKitFadingCircle(
                                    color: AppColors.azulPrimario,
                                    size: 40.0,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }

                            final product = _filteredProducts[index];
                            final isFavorite =
                                _favoriteProductIds.contains(product.id);

                            return ProductCard(
                              title: product.title,
                              description: product.description,
                              price: product.price,
                              imageUrl: product.imageUrl,
                              isFavorite: isFavorite,
                              isAvailable: product.isAvailable,
                              onToggleVisibility: () {
                                setState(() {
                                  final productIndex =
                                      _allProducts.indexOf(product);
                                  if (productIndex != -1) {
                                    _allProducts[productIndex] =
                                        product.copyWith(
                                            isAvailable: !product.isAvailable);
                                  }
                                  // Actualizar también en la lista filtrada si es necesario
                                  final filteredIndex =
                                      _filteredProducts.indexOf(product);
                                  if (filteredIndex != -1) {
                                    _filteredProducts[filteredIndex] =
                                        _allProducts[productIndex];
                                  }
                                });
                              },
                              onToggleFavorite: () {
                                _toggleFavorite(product);
                              },
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      ProductDetailModal(product: product),
                                );
                              },
                            );
                          },
                        ),
                        if (_selectedCategoryName != null &&
                            _filteredProducts.isEmpty &&
                            !_isLoadingProducts)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                  'No se encontraron productos en esta categoría.'),
                            ),
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

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      AppColors.azulPrimario,
      AppColors.amarilloPrimario,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.red,
      Colors.brown,
      Colors.blue,
      Colors.purple,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}
