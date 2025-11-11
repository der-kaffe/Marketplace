// lib/screens/home_screen.dart (actualizado con solución de duplicados y búsqueda por rango de precio)

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with RouteAware {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  // El "Master" de todos los productos, acceso instantáneo por ID.
  final Map<String, Product> _masterProductMap = {};
  // Lista de IDs que se deben mostrar en la UI, en orden.
  List<String> _filteredProductIds = [];

  List<ProductModel.ApiCategory> _apiCategories = [];
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = true;
  String? _errorCategories;
  int _page = 1;
  final int _limit = 20;
  final Set<String> _favoriteProductIds = {};

  String? _selectedCategoryName;
  int? _selectedCategoryId;
  bool _hasLoadedAllProducts = false; // Control para evitar cargas innecesarias

  // --- NUEVO: Estados para el filtro de rango de precio ---
  double? _precioMinimo;
  double? _precioMaximo;
  // --- FIN NUEVO ---

  @override
  void initState() {
    super.initState();

    // ✅ OPTIMIZACIÓN: Cargar todo en paralelo, no en serie.
    // Esto inicia todas las llamadas de red al mismo tiempo.
    _loadDataParalelamente();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingProducts &&
          _selectedCategoryId == null &&
          _precioMinimo == null &&
          _precioMaximo == null &&
          _masterProductMap.isNotEmpty &&
          !_hasLoadedAllProducts) {
        _loadMoreProducts();
      }
    });
  }

  // ✅ NUEVO MÉTODO HELPER para la carga paralela
  Future<void> _loadDataParalelamente() async {
    // Inicia todas las cargas y espera a que terminen juntas.
    // El usuario verá los productos, categorías y favoritos
    // aparecer casi al mismo tiempo.
    await Future.wait([
      _loadCategories(),
      _loadMoreProducts(),
      _loadFavorites(),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registrar el observer
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se llama cuando vuelves a Home desde otra pantalla
    forceRefreshProducts();
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
      // ✅ OPTIMIZACIÓN: Solo actualiza el Map.
      // El GridView leerá este cambio la próxima vez que se redibuje.
      setState(() {
        final updatedProduct = product.copyWith(isAvailable: newVisibility);
        _masterProductMap[product.id] = updatedProduct;
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

      print(
          '✅ Visibilidad actualizada: $newVisibility para producto #$productId');
    } catch (e) {
      // 7. MANEJO DE ERRORES MEJORADO
      print('❌ Error cambiando visibilidad: $e');

      String errorMessage = 'Error: ${e.toString()}'; // Mensaje por defecto
      Color errorColor = Colors.red; // Color por defecto

      // Comprobar si es un error de permiso
      if (e.toString().contains('No tienes permiso')) {
        errorMessage = 'No puedes ocultar una publicación que no te pertenece.';
        errorColor = Colors.orange; // Usar un color de "advertencia"
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: errorColor, // Usar el color dinámico
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para cargar productos (simula paginación)
  Future<void> _loadMoreProducts() async {
    if (_isLoadingProducts || _hasLoadedAllProducts) return;
    setState(() => _isLoadingProducts = true);

    try {
      final newProducts = await _productService.fetchProducts(
        page: _page,
        limit: _limit,
      );

      setState(() {
        if (newProducts.isEmpty || newProducts.length < _limit) {
          _hasLoadedAllProducts = true;
          print('✅ Todos los productos han sido cargados...');
        }

        // ✅ OPTIMIZACIÓN: Añadir a Map y a lista de IDs
        for (var product in newProducts) {
          _masterProductMap[product.id] = product;
        }

        // Si no hay filtro, añade los nuevos IDs a la lista visible
        if (_selectedCategoryId == null &&
            _precioMinimo == null &&
            _precioMaximo == null) {
          _filteredProductIds.addAll(newProducts.map((p) => p.id));
        }

        _page++;
      });
      print('✅ Productos cargados: ${newProducts.length}');
    } catch (e) {
      print('❌ Error cargando productos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando productos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> forceRefreshProducts() async {
    print('🔄 Forzando recarga de productos...');

    setState(() {
      _page = 1;
      // ✅ OPTIMIZACIÓN: Limpiar el Map y la lista de IDs
      _masterProductMap.clear();
      _filteredProductIds.clear();

      _selectedCategoryName = null;
      _selectedCategoryId = null;
      _precioMinimo = null;
      _precioMaximo = null;
      _hasLoadedAllProducts = false;
      _isLoadingProducts = false;
    });

    // Llama a _loadMoreProducts, que ahora llenará las nuevas estructuras
    await _loadMoreProducts();
  }

  void _removeProductFromUI(String productId) {
    setState(() {
      // ✅ OPTIMIZACIÓN: Eliminar de Map y de lista de IDs
      _masterProductMap.remove(productId);
      _filteredProductIds.remove(productId);
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

  void _applyCombinedFilter() {
    // ✅ OPTIMIZACIÓN: Iterar sobre 'values' del Map es más rápido que una lista
    List<Product> sourceList = _masterProductMap.values.toList();

    // Filtrar por categoría
    if (_selectedCategoryId != null) {
      Set<String> categoryNamesToFilter =
          _getAllSubcategoryNames(_selectedCategoryId!, _apiCategories);
      sourceList = sourceList.where((product) {
        return categoryNamesToFilter.contains(product.category);
      }).toList();
    }

    // Filtrar por precio
    if (_precioMinimo != null || _precioMaximo != null) {
      sourceList = sourceList.where((product) {
        bool passesMinCheck =
            _precioMinimo == null || product.price >= _precioMinimo!;
        bool passesMaxCheck =
            _precioMaximo == null || product.price <= _precioMaximo!;
        return passesMinCheck && passesMaxCheck;
      }).toList();
    }

    setState(() {
      // Almacena solo los IDs de los productos filtrados
      _filteredProductIds = sourceList.map((p) => p.id).toList();
    });

    print(
        '🔍 Aplicando filtro combinado. Productos filtrados: ${_filteredProductIds.length}');
  }

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
        '🔍 Filtrando por categoría: $categoryName (ID: $categoryId) y precio. Productos filtrados: ${_filteredProductIds.length}');
  }

  // --- ACTUALIZAR: _clearCategoryFilter para limpiar todos los filtros ---
  void _clearCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _precioMinimo = null;
      _precioMaximo = null;
      // ✅ OPTIMIZACIÓN: Restaura la lista de IDs desde las llaves del Map
      _filteredProductIds = _masterProductMap.keys.toList();
    });
    print(
        '🔍 Filtros limpiados. Mostrando todos los productos: ${_filteredProductIds.length}');
  }

  // --- NUEVO: Mapeo de iconos por categoría ---
  IconData _getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    switch (name) {
      // Principales
      case 'vehículos':
      case 'vehiculos':
        return Icons.directions_car;
      case 'propiedades':
        return Icons.home_filled;
      case 'electrónicos':
      case 'electronicos':
        return Icons.devices;
      case 'hogar y jardín':
      case 'hogar y jardin':
        return Icons.yard;
      case 'ropa y accesorios':
        return Icons.checkroom;
      case 'familia':
        return Icons.family_restroom;
      case 'ocio y entretenimiento':
        return Icons.local_activity;
      case 'mascotas':
        return Icons.pets;
      case 'deportes':
        return Icons.sports_soccer;
      case 'juguetes y juegos':
        return Icons.toys;
      case 'servicios':
        return Icons.handyman;
      case 'empleos':
        return Icons.work;
      case 'gratis':
        return Icons.card_giftcard;
      case 'clasificados':
        return Icons.campaign;
      case 'libros':
        return Icons.menu_book;

      // Subcategorías comunes
      case 'autos':
        return Icons.directions_car_filled;
      case 'motos':
        return Icons.two_wheeler;
      case 'camionetas y suv':
        return Icons.directions_car;
      case 'repuestos y accesorios':
        return Icons.build;
      case 'bicicletas':
        return Icons.pedal_bike;

      case 'arriendo':
        return Icons.apartment;
      case 'venta':
        return Icons.house_siding;
      case 'habitaciones':
        return Icons.bed;

      case 'computadoras':
        return Icons.computer;
      case 'laptops':
        return Icons.laptop_mac;
      case 'smartphones':
        return Icons.phone_android;
      case 'tablets':
        return Icons.tablet_mac;
      case 'audio y parlantes':
        return Icons.speaker;
      case 'consolas y videojuegos':
        return Icons.sports_esports;
      case 'accesorios':
        return Icons.memory;

      case 'muebles':
        return Icons.chair_alt;
      case 'electrodomésticos':
      case 'electrodomesticos':
        return Icons.kitchen;
      case 'decoración':
      case 'decoracion':
        return Icons.emoji_objects;
      case 'herramientas':
        return Icons.handyman;
      case 'jardinería':
      case 'jardineria':
        return Icons.yard;

      case 'hombre':
        return Icons.male;
      case 'mujer':
        return Icons.female;
      case 'niños':
      case 'ninos':
        return Icons.child_friendly;
      case 'calzado':
        return Icons.hiking;
      case 'bolsos y accesorios':
        return Icons.shopping_bag;

      case 'bebés':
      case 'bebes':
        return Icons.baby_changing_station;
      case 'cuidado infantil':
        return Icons.stroller;

      case 'libros y revistas':
        return Icons.menu_book;
      case 'música e instrumentos':
      case 'musica e instrumentos':
        return Icons.music_note;
      case 'coleccionables':
        return Icons.auto_awesome;

      case 'alimentos y accesorios':
        return Icons.pets;
      case 'adopciones':
        return Icons.volunteer_activism;

      case 'fitness':
        return Icons.fitness_center;
      case 'ciclismo':
        return Icons.pedal_bike;
      case 'fútbol':
      case 'futbol':
        return Icons.sports_soccer;

      case 'juegos de mesa':
        return Icons.table_rows;
      case 'juguetes educativos':
        return Icons.extension;

      case 'clases particulares':
        return Icons.menu_book;
      case 'reparaciones':
        return Icons.build_circle;
      case 'limpieza':
        return Icons.cleaning_services;

      case 'tiempo completo':
        return Icons.work;
      case 'medio tiempo':
        return Icons.work_outline;
      case 'freelance':
        return Icons.laptop_mac;

      case 'anuncios':
        return Icons.campaign;
      case 'intercambios':
        return Icons.swap_horiz;

      case 'regalos':
        return Icons.card_giftcard;

      case 'académicos':
      case 'academicos':
        return Icons.school;
      case 'ficción':
      case 'ficcion':
        return Icons.menu_book_outlined;
      case 'no ficción':
      case 'no ficcion':
        return Icons.menu_book_rounded;

      case 'todo':
        return Icons.apps;
      default:
        return Icons.category;
    }
  }

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
        // ✅ OPTIMIZACIÓN: Filtrar el Map y solo devolver los IDs
        _filteredProductIds = _masterProductMap.values
            .where((product) {
              final titleNorm = _normalizeText(product.title);
              final descNorm = _normalizeText(product.description);
              return titleNorm.contains(normalizedQuery) ||
                  descNorm.contains(normalizedQuery);
            })
            .map((p) => p.id)
            .toList(); // Solo guarda los IDs
      }
    });
  }
  // --- FIN NUEVO ---

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECCIÓN 1: Comprobar el Map en lugar de la lista antigua
    if (_isLoadingProducts && _masterProductMap.isEmpty) {
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
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.azulPrimario),
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
                borderSide: const BorderSide(
                    color: AppColors.amarilloPrimario, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              _searchProductsByText(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.filter_alt, color: AppColors.amarilloPrimario),
            onPressed: _showPriceFilterModal,
            tooltip: 'Filtrar por precio',
          ),
        ],
      ),
      backgroundColor: AppColors.fondoClaro,
      body: RefreshIndicator(
        onRefresh: forceRefreshProducts,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
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
                      AppColors.azulPrimario.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azulPrimario.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
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
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Image.asset('assets/logoMarket.png',
                          fit: BoxFit.contain),
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
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.azulPrimario,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Categorías',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulPrimario,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height:
                            150, // Aumentar altura para dar espacio a la sombra
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              vertical: 5), // Padding vertical para la sombra
                          itemCount:
                              _apiCategories.length + 1, // +1 para "Todo"
                          itemBuilder: (context, index) {
                            // Primera tarjeta es "Todo"
                            if (index == 0) {
                              return Container(
                                margin:
                                    const EdgeInsets.only(left: 20, right: 12),
                                child: CategoryCard(
                                  icon: _getIconForCategory('todo'),
                                  title: 'Todo',
                                  color: AppColors.azulPrimario,
                                  onTap: () {
                                    _clearCategoryFilter();
                                  },
                                ),
                              );
                            }

                            // Resto de categorías
                            final category = _apiCategories[index - 1];
                            Color color = _getCategoryColor(index - 1);
                            String title = category.nombre;
                            IconData icon =
                                _getIconForCategory(category.nombre);

                            return Container(
                              margin: EdgeInsets.only(
                                right: index == _apiCategories.length ? 20 : 12,
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
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.azulPrimario,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Categorías',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulPrimario,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
                            Text(
                                'Error al cargar categorías: $_errorCategories'),
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
                      const Center(
                          child: Text('No hay categorías disponibles.')),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
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
                                      .withOpacity(0.1),
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
                          _filteredProductIds.isEmpty && !_isLoadingProducts
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Text(
                                      'No se encontraron productos.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filteredProductIds.length +
                                      (_isLoadingProducts &&
                                              _selectedCategoryName == null
                                          ? 1
                                          : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= _filteredProductIds.length) {
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

                                    final productId =
                                        _filteredProductIds[index];
                                    final product =
                                        _masterProductMap[productId];

                                    // Si el producto es nulo (no debería pasar),
                                    // muestra un contenedor vacío.
                                    if (product == null) {
                                      print(
                                          '❌ Error: Producto con ID $productId no encontrado en el Map.');
                                      return Container();
                                    }

                                    final isFavorite = _favoriteProductIds
                                        .contains(product.id);                                    return ProductCard(
                                      title: product.title,
                                      description: product.description,
                                      price: product.price,
                                      imageUrl: product.imageUrl,
                                      imagenes: product
                                          .imagenes, // 🖼️ Múltiples imágenes
                                      isFavorite: isFavorite,
                                      isAvailable: product.isAvailable,
                                      estadoProducto: product.estadoProducto,
                                      tiempoUso: product.tiempoUso,
                                      // 👤 Información del vendedor
                                      sellerId: product.sellerId,
                                      sellerName: product.sellerName,
                                      sellerAvatar: product.sellerAvatar,
                                      onToggleVisibility: () =>
                                          _toggleProductVisibility(product),
                                      onToggleFavorite: () =>
                                          _toggleFavorite(product),
                                      onTap: () async {
                                        print(
                                            '🆔 ID del producto: ${product.id}');
                                        final deletedProductId =
                                            await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => ProductDetailModal(
                                              product: product),
                                        );

                                        if (deletedProductId != null) {
                                          _removeProductFromUI(
                                              deletedProductId);
                                        }
                                      },
                                    );
                                  },
                                ),
                          // Mensaje si hay filtro de categoría pero no hay productos
                          // ✅ CORRECCIÓN 2: Comprobar _filteredProductIds
                          if (_selectedCategoryName != null &&
                              _filteredProductIds.isEmpty &&
                              !_isLoadingProducts)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                    'No se encontraron productos en esta categoría.'),
                              ),
                            ),

                          // Mensaje si hay filtro de precio pero no hay productos
                          // ✅ CORRECCIÓN 3: Comprobar _filteredProductIds
                          if (_precioMinimo != null || _precioMaximo != null)
                            if (_filteredProductIds.isEmpty &&
                                !_isLoadingProducts)
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
