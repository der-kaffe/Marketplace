// lib/screens/home_screen.dart (actualizado con solución de duplicados y búsqueda por rango de precio)

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
import 'package:flutter/services.dart'; // Importante para TextInputFormatter

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
  final int _limit = 20;
  final Set<String> _favoriteProductIds = {};

  String? _selectedCategoryName;
  int? _selectedCategoryId;

  // --- NUEVO: Estados para el filtro de rango de precio ---
  double? _precioMinimo;
  double? _precioMaximo;
  // --- FIN NUEVO ---

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

  // ✅ NUEVO: Método para cambiar visibilidad (conectado al backend)
  Future<void> _toggleProductVisibility(Product product) async {
    try {
      // 1. Obtener el ID numérico del producto
      final productId = int.tryParse(product.id);
      if (productId == null) {
        throw Exception('ID de producto inválido');
      }

      // 2. Calcular nuevo estado
      final newVisibility = !product.isAvailable;

      // 3. Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Actualizando visibilidad...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // 4. Llamar al backend
      await _productService.toggleVisibility(
        productId: productId,
        visible: newVisibility,
      );

      // 5. Actualizar UI local solo si la petición fue exitosa
      setState(() {
        // Actualizar en _allProducts
        final productIndex = _allProducts.indexWhere((p) => p.id == product.id);
        if (productIndex != -1) {
          _allProducts[productIndex] = product.copyWith(isAvailable: newVisibility);
        }

        // Actualizar en _originalProducts
        final originalIndex = _originalProducts.indexWhere((p) => p.id == product.id);
        if (originalIndex != -1) {
          _originalProducts[originalIndex] = product.copyWith(isAvailable: newVisibility);
        }

        // Actualizar en _filteredProducts
        final filteredIndex = _filteredProducts.indexWhere((p) => p.id == product.id);
        if (filteredIndex != -1) {
          _filteredProducts[filteredIndex] = product.copyWith(isAvailable: newVisibility);
        }
      });

      // 6. Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newVisibility 
                ? '✅ Producto visible para todos' 
                : '🔒 Producto oculto',
            ),
            backgroundColor: newVisibility ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ Visibilidad actualizada: $newVisibility para producto #$productId');

    } catch (e) {
      // 7. Manejo de errores
      print('❌ Error cambiando visibilidad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para cargar productos (simula paginación)
  Future<void> _loadMoreProducts() async {
    // ⬇️ 1. GUARDIÁN SIMPLIFICADO
    //    Tu scroll listener ya comprueba el filtro de categoría, 
    //    así que aquí solo evitamos cargas duplicadas.
    if (_isLoadingProducts) return;

    // 2. Establecer la animación de carga
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
          _originalProducts.addAll(newProducts); // Guardar copia limpia original
          _filteredProducts = List.from(_originalProducts); // Mostrar originales

        } else {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando productos: $e')),
        );
      }
    } finally {
      // ⬇️ 3. ¡LA SOLUCIÓN!
      //    Esto se ejecuta SIEMPRE (éxito o error) y apaga la animación.
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> forceRefreshProducts() async {
      print('🔄 Forzando recarga de productos...');
      
      // 1. Limpia las listas y filtros
      setState(() {
        _page = 1;
        _allProducts.clear();
        _originalProducts.clear();
        _filteredProducts.clear();
        
        _selectedCategoryName = null; 
        _selectedCategoryId = null;
        _precioMinimo = null;
        _precioMaximo = null;
        
        // ❌ 2. NO PONGAS _isLoadingProducts = true AQUÍ
        //    Deja que _loadMoreProducts() lo haga.
        // _isLoadingProducts = true; 
      });

      // 3. Llama a la función de carga.
      //    Como _isLoadingProducts es 'false', el guardián de
      //    _loadMoreProducts pasará sin problemas.
      await _loadMoreProducts();
    }

  // ✅ PASO 2: (YA LO TIENES) Asegúrate de tener esta función del paso anterior
  void _removeProductFromUI(String productId) {
    setState(() {
      _originalProducts.removeWhere((p) => p.id == productId);
      _filteredProducts.removeWhere((p) => p.id == productId);
      _allProducts.removeWhere((p) => p.id == productId); // Asegúrate de limpiar las 3 listas
    });
    print('✅ UI actualizada. Producto $productId eliminado de la lista.');
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

  // --- NUEVO: Método para abrir el modal de filtros ---
  void _showPriceFilterModal() {
    final TextEditingController minController = TextEditingController();
    final TextEditingController maxController = TextEditingController();

    // Pre-cargar valores si ya están establecidos
    if (_precioMinimo != null)
      minController.text = _precioMinimo!.toStringAsFixed(0);
    if (_precioMaximo != null)
      maxController.text = _precioMaximo!.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filtrar por precio',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: minController,
                      decoration: const InputDecoration(
                        labelText: 'Precio mínimo',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Solo números
                      onChanged: (value) {
                        // Opcional: Validar aquí o dejar que el usuario limpie el campo
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: maxController,
                      decoration: const InputDecoration(
                        labelText: 'Precio máximo',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Solo números
                      onChanged: (value) {
                        // Opcional: Validar aquí o dejar que el usuario limpie el campo
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Limpiar filtros de precio
                            setModalState(() {
                              _precioMinimo = null;
                              _precioMaximo = null;
                              minController.text = '';
                              maxController.text = '';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey, // Color para limpiar
                          ),
                          child: const Text('Limpiar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Aplicar filtros de precio
                            double? min = minController.text.isEmpty
                                ? null
                                : double.tryParse(minController.text);
                            double? max = maxController.text.isEmpty
                                ? null
                                : double.tryParse(maxController.text);

                            // Validación simple: si ambos están presentes, min debe ser <= max
                            if (min != null && max != null && min > max) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Precio mínimo no puede ser mayor que precio máximo.')),
                              );
                              return;
                            }

                            setState(() {
                              _precioMinimo = min;
                              _precioMaximo = max;
                            });

                            // Aplicar el filtro combinado (categoría + precio)
                            _applyCombinedFilter();

                            Navigator.pop(context); // Cerrar modal
                          },
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  // --- FIN NUEVO ---

  // --- NUEVO: Método para aplicar el filtro combinado ---
  void _applyCombinedFilter() {
    setState(() {
      // Comienza con la lista original
      _filteredProducts = List.from(_originalProducts);

      // Filtrar por categoría si hay una seleccionada
      if (_selectedCategoryId != null) {
        Set<String> categoryNamesToFilter =
            _getAllSubcategoryNames(_selectedCategoryId!, _apiCategories);
        _filteredProducts = _filteredProducts.where((product) {
          return categoryNamesToFilter.contains(product.category);
        }).toList();
      }

      // Filtrar por precio si hay un rango establecido
      if (_precioMinimo != null || _precioMaximo != null) {
        _filteredProducts = _filteredProducts.where((product) {
          bool passesMinCheck =
              _precioMinimo == null || product.price >= _precioMinimo!;
          bool passesMaxCheck =
              _precioMaximo == null || product.price <= _precioMaximo!;
          return passesMinCheck && passesMaxCheck;
        }).toList();
      }
    });
    print(
        '🔍 Aplicando filtro combinado. Productos filtrados: ${_filteredProducts.length}');
  }
  // --- FIN NUEVO ---

  // --- ACTUALIZAR: _filterProductsByCategory para usar _applyCombinedFilter ---
  void _filterProductsByCategory(int? categoryId, String? categoryName) {
    print('--- DEBUG _filterProductsByCategory ---');
    print('Categoría seleccionada: $categoryName (ID: $categoryId)');
    print('Precio Min: $_precioMinimo, Precio Max: $_precioMaximo');
    print('---------------------------------------');

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      // No limpiar _precioMinimo/_precioMaximo aquí si solo cambia la categoría
    });

    // Aplicar el filtro combinado (categoría + precio)
    _applyCombinedFilter();

    _page = 1; // Reiniciar página si se aplica un filtro
    print(
        '🔍 Filtrando por categoría: $categoryName (ID: $categoryId) y precio. Productos filtrados: ${_filteredProducts.length}');
  }
  // --- FIN ACTUALIZAR ---

  // --- ACTUALIZAR: _clearCategoryFilter para usar _applyCombinedFilter ---
  void _clearCategoryFilter() {
    _filterProductsByCategory(null, null);
  }
  // --- FIN ACTUALIZAR ---

  // --- NUEVO: Búsqueda de productos por texto (ignora tildes/acentos) ---
  String _normalizeText(String text) {
    // Quita tildes/acentos y pasa a minúsculas
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n');
  }

  void _searchProductsByText(String query) {
    setState(() {
      if (query.isEmpty) {
        _applyCombinedFilter();
      } else {
        final normalizedQuery = _normalizeText(query);
        _filteredProducts = _originalProducts.where((product) {
          final titleNorm = _normalizeText(product.title);
          final descNorm = _normalizeText(product.description);
          return titleNorm.contains(normalizedQuery) || descNorm.contains(normalizedQuery);
        }).toList();
      }
    });
  }
  // --- FIN NUEVO ---

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
      appBar: AppBar(
        backgroundColor: AppColors.azulPrimario,
        elevation: 0,
        title: SizedBox(
          height: 44,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search, color: AppColors.azulPrimario),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.azulPrimario),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.azulPrimario),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.amarilloPrimario, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              _searchProductsByText(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: AppColors.amarilloPrimario),
            onPressed: _showPriceFilterModal,
            tooltip: 'Filtrar por precio',
          ),
        ],
      ),
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
                              // ✅ CAMBIAR: Usar el nuevo método conectado al backend
                              onToggleVisibility: () => _toggleProductVisibility(product),
                              onToggleFavorite: () => _toggleFavorite(product),
                              
                              // 👇 AQUÍ ESTÁ EL CAMBIO 👇
                              onTap: () async { // 1. Marcar la función como 'async'
                                print('🆔 ID del producto: ${product.id}');
                                
                                // 2. Usar 'await' y especificar que esperamos un <String>
                                final deletedProductId = await showModalBottomSheet<String>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ProductDetailModal(product: product),
                                );

                                // 3. Comprobar si recibimos un ID de vuelta
                                if (deletedProductId != null) {
                                  // 4. Llamar a la función que actualiza la UI
                                  _removeProductFromUI(deletedProductId);
                                }
                              },
                              // 👆 FIN DEL CAMBIO 👆
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
                        // Mensaje si hay filtro de precio activo pero no hay productos
                        if (_precioMinimo != null || _precioMaximo != null)
                          if (_filteredProducts.isEmpty && !_isLoadingProducts)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                    'No se encontraron productos en el rango de precio.'),
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
