import 'package:flutter/material.dart';
import '../models/product_model.dart' as ProductModel;
import '../models/seller_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ProductService {
  static const String _defaultImage = 'assets/producto_sin_foto.jpg';
  final ApiClient _apiClient =
      ApiClient(baseUrl: getDefaultBaseUrl()); // 🔧 Usar función helper
  final AuthService _authService = AuthService();

  // 🔧 CONFIGURACIÓN MODULAR - Fácil de cambiar
  // 🔧 CAMBIAR AQUÍ PARA ELEGIR ORIGEN DE DATOS:

  // Solo BD:
  //static const ProductDataSource _dataSource = ProductDataSource.database;

  // Solo simulados:
  //static const ProductDataSource _dataSource = ProductDataSource.simulated;

  // Híbrido (BD + simulados de respaldo):
  static const ProductDataSource _dataSource = ProductDataSource.database;

  // ✅ MÉTODO PRINCIPAL MODULAR
  Future<List<ProductModel.Product>> fetchProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    switch (_dataSource) {
      case ProductDataSource.database:
        return await _fetchFromDatabase(
            page: page, limit: limit, category: category, search: search);

      case ProductDataSource.simulated:
        return await _fetchSimulated(page: page, limit: limit);

      case ProductDataSource.hybrid:
        return await _fetchHybrid(
            page: page, limit: limit, category: category, search: search);
    }
  }

  // 🗄️ SOLO BASE DE DATOS
  Future<List<ProductModel.Product>> _fetchFromDatabase({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _apiClient.setToken(token);
      }

      final response = await _apiClient.getProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      print('✅ Productos de BD: ${response.products.length}');
      return response.products.map((p) => p.toProductModel()).toList();
    } catch (e) {
      print('❌ Error BD: $e');
      return []; // Retorna lista vacía si falla
    }
  }

  // 🎭 SOLO SIMULADOS
  Future<List<ProductModel.Product>> _fetchSimulated({
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simula red
    final start = (page - 1) * limit;
    final end = (start + limit > _simulatedProducts.length)
        ? _simulatedProducts.length
        : start + limit;

    if (start >= _simulatedProducts.length) return [];

    final productos = _simulatedProducts.sublist(start, end);
    print('✅ Productos simulados: ${productos.length}');
    return productos;
  }

  // 🔄 HÍBRIDO: BD + Simulados (fallback inteligente)
  Future<List<ProductModel.Product>> _fetchHybrid({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      // 1. Intentar obtener de BD
      final dbProducts = await _fetchFromDatabase(
          page: page, limit: limit, category: category, search: search);

      // 2. Si BD tiene productos suficientes, usarlos
      if (dbProducts.length >= limit) {
        print('✅ Híbrido: Usando ${dbProducts.length} productos de BD');
        return dbProducts;
      }

      // 3. Si BD no tiene suficientes, completar con simulados
      final needed = limit - dbProducts.length;
      final simulatedPage =
          ((page - 1) * limit - dbProducts.length / limit).ceil().clamp(1, 999);

      final simulatedProducts = await _fetchSimulated(
        page: simulatedPage,
        limit: needed,
      );

      final combined = [...dbProducts, ...simulatedProducts];
      print(
          '✅ Híbrido: ${dbProducts.length} BD + ${simulatedProducts.length} simulados = ${combined.length}');

      return combined;
    } catch (e) {
      print('❌ Error híbrido, fallback a simulados: $e');
      return await _fetchSimulated(page: page, limit: limit);
    }
  }

  final List<String> _campusUcTemuco = [
    "Campus San Francisco",
    "Campus Los Castaños",
    "Campus Manuel Montt",
    "Campus San Juan Pablo II"
  ];

  final List<ProductModel.Product> _simulatedProducts = [
    ProductModel.Product(
      id: '1',
      title: 'Smartphone Galaxy S23',
      description: 'Teléfono de última generación con 256GB de memoria',
      price: 699999,
      imageUrl:
          'https://www.reuse.cl/cdn/shop/files/smartphone-samsung-galaxy-s23-fe-256gb-verde-reacondicionado-6283113.png?v=1751675580&width=1000',
      rating: 4.8,
      reviewCount: 120,
      category: 'electronica',
      isAvailable: true,
      sellerId: 'seller1',
      sellerName: 'Juan Pérez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
    ),
    ProductModel.Product(
      id: '2',
      title: 'Zapatillas Running',
      description: 'Zapatillas deportivas para running con suela amortiguada',
      price: 89990,
      imageUrl:
          'https://assets.adidas.com/images/w_600,f_auto,q_auto/123456_adidas-running-shoes.jpg',
      rating: 4.6,
      reviewCount: 95,
      category: 'deportes',
      sellerId: 'seller2',
      sellerName: 'Laura Gómez',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/2.jpg',
    ),
    ProductModel.Product(
      id: '3',
      title: 'Chaqueta de Cuero',
      description: 'Chaqueta de cuero genuino con forro interior',
      price: 129990,
      imageUrl:
          'https://cdn.shopify.com/s/files/1/0271/3135/9281/products/chaqueta_cuero_negro_600x600.jpg',
      rating: 4.5,
      reviewCount: 78,
      category: 'ropa',
      sellerId: 'seller3',
      sellerName: 'Carlos López',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/3.jpg',
    ),
    ProductModel.Product(
      id: '4',
      title: 'Anillo de Plata',
      description: 'Anillo de plata 925 con diseño minimalista',
      price: 35000,
      imageUrl:
          'https://cdn.shopify.com/s/files/1/0269/4393/9899/products/anillo-plata-minimalista-600x600.jpg',
      rating: 4.7,
      reviewCount: 105,
      category: 'joyas',
      sellerId: 'seller4',
      sellerName: 'Ana Torres',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/4.jpg',
    ),
    ProductModel.Product(
      id: '5',
      title: 'Set de Maquillaje',
      description:
          'Set completo de maquillaje con paleta de sombras y labiales',
      price: 45990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2018/03/13/21/28/makeup-3225174_1280.jpg',
      rating: 4.9,
      reviewCount: 150,
      category: 'belleza',
      sellerId: 'seller5',
      sellerName: 'Marta Fernández',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/5.jpg',
    ),
    ProductModel.Product(
      id: '6',
      title: 'Lámpara Moderna',
      description: 'Lámpara de mesa con diseño contemporáneo',
      price: 39990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2017/01/31/17/47/lamp-2029073_1280.jpg',
      rating: 4.4,
      reviewCount: 65,
      category: 'hogar',
      sellerId: 'seller6',
      sellerName: 'Pedro Martínez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/6.jpg',
    ),
    ProductModel.Product(
      id: '7',
      title: 'Audífonos Bluetooth',
      description: 'Sonido de alta calidad con cancelación de ruido',
      price: 54990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/11/29/10/07/headphones-1868617_1280.jpg',
      rating: 4.3,
      reviewCount: 210,
      category: 'electronica',
      sellerId: 'seller1',
      sellerName: 'Juan Pérez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
    ),
    ProductModel.Product(
      id: '8',
      title: 'Pelota de Fútbol',
      description: 'Pelota oficial tamaño 5',
      price: 15990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2014/12/27/15/41/football-581074_1280.jpg',
      rating: 4.1,
      reviewCount: 88,
      category: 'deportes',
      sellerId: 'seller2',
      sellerName: 'Laura Gómez',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/2.jpg',
    ),
    ProductModel.Product(
      id: '9',
      title: 'Polera Estampada',
      description: 'Polera 100% algodón con diseño original',
      price: 12990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/03/27/21/50/t-shirt-1280007_1280.jpg',
      rating: 4.2,
      reviewCount: 67,
      category: 'ropa',
      sellerId: 'seller3',
      sellerName: 'Carlos López',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/3.jpg',
    ),
    ProductModel.Product(
      id: '10',
      title: 'Collar de Acero',
      description: 'Collar con dije minimalista',
      price: 24990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2017/03/14/02/12/necklace-2132311_1280.jpg',
      rating: 4.6,
      reviewCount: 50,
      category: 'joyas',
      sellerId: 'seller4',
      sellerName: 'Ana Torres',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/4.jpg',
    ),
    ProductModel.Product(
      id: '11',
      title: 'Perfume Floral',
      description: 'Aroma fresco y duradero',
      price: 69990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/03/31/19/54/perfume-1299396_1280.jpg',
      rating: 4.8,
      reviewCount: 190,
      category: 'belleza',
      sellerId: 'seller5',
      sellerName: 'Marta Fernández',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/5.jpg',
    ),
    ProductModel.Product(
      id: '12',
      title: 'Sillón Reclinable',
      description: 'Comodidad premium para tu sala de estar',
      price: 299990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/03/27/22/22/armchair-1280950_1280.jpg',
      rating: 4.9,
      reviewCount: 73,
      category: 'hogar',
      sellerId: 'seller6',
      sellerName: 'Pedro Martínez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/6.jpg',
    ),
    ProductModel.Product(
      id: '13',
      title: 'Smartwatch Fit',
      description: 'Monitorea tu actividad física y salud',
      price: 89990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2018/01/17/07/26/smartwatch-3080846_1280.jpg',
      rating: 4.5,
      reviewCount: 220,
      category: 'electronica',
      sellerId: 'seller1',
      sellerName: 'Juan Pérez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
    ),
    ProductModel.Product(
      id: '14',
      title: 'Raqueta de Tenis',
      description: 'Raqueta profesional ligera y resistente',
      price: 75990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2017/06/22/19/12/tennis-2434815_1280.jpg',
      rating: 4.4,
      reviewCount: 130,
      category: 'deportes',
      sellerId: 'seller2',
      sellerName: 'Laura Gómez',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/2.jpg',
    ),
    ProductModel.Product(
      id: '15',
      title: 'Vestido de Fiesta',
      description: 'Vestido elegante para ocasiones especiales',
      price: 119990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/03/27/21/52/dress-1280011_1280.jpg',
      rating: 4.7,
      reviewCount: 140,
      category: 'ropa',
      sellerId: 'seller3',
      sellerName: 'Carlos López',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/3.jpg',
    ),
    ProductModel.Product(
      id: '16',
      title: 'Toyota Corolla 2020',
      description: 'Automóvil en excelente estado, único dueño',
      price: 12500000,
      imageUrl:
          'https://cdn.pixabay.com/photo/2014/10/23/18/05/car-500234_1280.jpg',
      rating: 4.8,
      reviewCount: 45,
      category: 'vehiculos',
      sellerId: 'seller7',
      sellerName: 'Ricardo Silva',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/7.jpg',
    ),
    ProductModel.Product(
      id: '17',
      title: 'Casa en Las Condes',
      description: 'Casa de 3 dormitorios con jardín',
      price: 180000000,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/11/29/03/53/architecture-1867187_1280.jpg',
      rating: 4.9,
      reviewCount: 12,
      category: 'inmuebles',
      sellerId: 'seller8',
      sellerName: 'Valentina Rojas',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/8.jpg',
    ),
    ProductModel.Product(
      id: '18',
      title: 'Cuna de Bebé',
      description: 'Cuna convertible con colchón incluido',
      price: 159990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2017/07/02/20/15/crib-2471391_1280.jpg',
      rating: 4.6,
      reviewCount: 78,
      category: 'bebes_ninos',
      sellerId: 'seller9',
      sellerName: 'Sofía Herrera',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/9.jpg',
    ),
    ProductModel.Product(
      id: '19',
      title: 'LEGO Creator 3-en-1',
      description: 'Set de construcción para niños de 8+ años',
      price: 89990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/03/31/19/58/lego-1299401_1280.jpg',
      rating: 4.8,
      reviewCount: 156,
      category: 'juguetes',
      sellerId: 'seller9',
      sellerName: 'Sofía Herrera',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/9.jpg',
    ),
    ProductModel.Product(
      id: '20',
      title: 'Taladro Inalámbrico',
      description: 'Taladro de 18V con baterías incluidas',
      price: 69990,
      imageUrl:
          'https://cdn.pixabay.com/photo/2017/07/21/19/55/drill-2523361_1280.jpg',
      rating: 4.5,
      reviewCount: 89,
      category: 'herramientas',
      sellerId: 'seller10',
      sellerName: 'Ignacio Muñoz',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/10.jpg',
    ),
  ];

  List<ProductModel.Product> _getSimulatedProducts() {
    return List.from(_simulatedProducts);
  }

  /// Obtiene info dinámica del vendedor
  Seller getSellerInfo(String sellerId) {
    final sellerProducts =
        _simulatedProducts.where((p) => p.sellerId == sellerId).toList();

    if (sellerProducts.isEmpty) {
      return Seller(
        name: "Vendedor desconocido",
        avatar: "https://via.placeholder.com/150",
        location: _campusUcTemuco[0],
        reputation: 0.0,
        totalSales: 0,
        activeListings: 0,
        soldListings: 0,
      );
    }

  
    final firstProduct = sellerProducts.first;
    final totalSales = sellerProducts.length;
    final activeListings = sellerProducts.where((p) => p.isAvailable).length;
    final soldListings = sellerProducts.where((p) => !p.isAvailable).length;

    // Campus aleatorio
    final location = (_campusUcTemuco..shuffle()).first;

    // Reputación promedio
    final reputation =
        sellerProducts.map((p) => p.rating).reduce((a, b) => a + b) /
            sellerProducts.length;

    return Seller(
      name: firstProduct.sellerName ?? "Vendedor",
      avatar: firstProduct.sellerAvatar ?? "https://via.placeholder.com/150",
      location: location,
      reputation: reputation,
      totalSales: totalSales,
      activeListings: activeListings,
      soldListings: soldListings,
    );
  }

  /// Lista de categorías simuladas
  final List<ProductModel.Category> _categories = [
    const ProductModel.Category(
      id: 'vehiculos',
      name: 'Vehículos',
      description: 'Autos, motos y accesorios automotrices',
      iconName: 'directions_car',
    ),
    const ProductModel.Category(
      id: 'inmuebles',
      name: 'Propiedades / Inmuebles',
      description: 'Compra y venta de propiedades',
      iconName: 'home',
    ),
    const ProductModel.Category(
      id: 'electronica',
      name: 'Electrónica',
      description: 'Gadgets, computadoras y accesorios',
      iconName: 'devices',
    ),
    const ProductModel.Category(
      id: 'hogar',
      name: 'Hogar y jardín',
      description: 'Muebles, decoración y jardinería',
      iconName: 'chair',
    ),
    const ProductModel.Category(
      id: 'ropa',
      name: 'Moda y accesorios',
      description: 'Ropa, zapatos y accesorios para todas las edades',
      iconName: 'checkroom',
    ),
    const ProductModel.Category(
      id: 'bebes_ninos',
      name: 'Bebés y niños',
      description: 'Productos para bebés y niños',
      iconName: 'child_care',
    ),
    const ProductModel.Category(
      id: 'juguetes',
      name: 'Juguetes y juegos',
      description: 'Juguetes, juegos de mesa y entretenimiento',
      iconName: 'toys',
    ),
    const ProductModel.Category(
      id: 'herramientas',
      name: 'Herramientas',
      description: 'Herramientas de trabajo y bricolaje',
      iconName: 'build',
    ),
    const ProductModel.Category(
      id: 'deportes',
      name: 'Deportes y ocio',
      description: 'Artículos deportivos y recreación',
      iconName: 'sports_soccer',
    ),
    const ProductModel.Category(
      id: 'mascotas',
      name: 'Mascotas y productos para animales',
      description: 'Accesorios y productos para mascotas',
      iconName: 'pets',
    ),
    const ProductModel.Category(
      id: 'joyas',
      name: 'Joyas',
      description: 'Accesorios y joyería',
      iconName: 'diamond',
    ),
    const ProductModel.Category(
      id: 'belleza',
      name: 'Belleza',
      description: 'Cosméticos y cuidado personal',
      iconName: 'spa',
    ),
    const ProductModel.Category(
      id: 'servicios',
      name: 'Servicios',
      description: 'Servicios profesionales y técnicos',
      iconName: 'work',
    ),
    const ProductModel.Category(
      id: 'alquileres',
      name: 'Alquileres',
      description: 'Alquiler de productos y espacios',
      iconName: 'apartment',
    ),
  ];

  /// Métodos de utilidad
  List<ProductModel.Product> getAllProducts() => List.from(_simulatedProducts);

  List<ProductModel.Product> getProductsByCategory(String categoryId) =>
      _simulatedProducts
          .where((product) => product.category == categoryId)
          .toList();

  List<ProductModel.Product> getFeaturedProducts({int limit = 4}) {
    final sortedProducts = List<ProductModel.Product>.from(_simulatedProducts)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sortedProducts.take(limit).toList();
  }

  List<ProductModel.Product> getFavoriteProducts() =>
      _simulatedProducts.where((product) => product.isFavorite).toList();

  ProductModel.Product? getProductById(String id) {
    try {
      return _simulatedProducts.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel.Category> getAllCategories() => List.from(_categories);

  ProductModel.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  static IconData getIconForName(String iconName) {
    switch (iconName) {
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'devices':
        return Icons.devices;
      case 'chair':
        return Icons.chair;
      case 'checkroom':
        return Icons.checkroom;
      case 'child_care':
        return Icons.child_care;
      case 'toys':
        return Icons.toys;
      case 'build':
        return Icons.build;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'pets':
        return Icons.pets;
      case 'diamond':
        return Icons.diamond;
      case 'spa':
        return Icons.spa;
      case 'work':
        return Icons.work;
      case 'apartment':
        return Icons.apartment;
      default:
        return Icons.category;
    }
  }
}

// 🔧 ENUM para configurar fácilmente el origen de datos
enum ProductDataSource {
  database, // Solo productos reales de BD
  simulated, // Solo productos simulados
  hybrid, // BD + simulados como fallback
}
