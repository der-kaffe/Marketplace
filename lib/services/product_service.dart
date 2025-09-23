import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Clase para gestionar los productos de la aplicación
class ProductService {
  static const String _defaultImage = 'assets/producto_sin_foto.jpg';

  /// Lista de productos simulados para la aplicación
  final List<Product> _products = [
    Product(
      id: '1',
      title: 'Smartphone Galaxy S23',
      description: 'Teléfono de última generación con 256GB de memoria',
      price: 699999,
      imageUrl:
          'https://www.reuse.cl/cdn/shop/files/smartphone-samsung-galaxy-s23-fe-256gb-verde-reacondicionado-6283113.png?v=1751675580&width=1000',
      rating: 4.8,
      reviewCount: 120,
      category: 'electronica',
      sellerName: 'Juan Pérez',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
    ),
    Product(
      id: '2',
      title: 'Zapatillas Running',
      description: 'Zapatillas deportivas para running con suela amortiguada',
      price: 89990,
      imageUrl: _defaultImage,
      rating: 4.6,
      reviewCount: 95,
      category: 'deportes',
      sellerName: 'Laura Gómez',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/2.jpg',
    ),
    Product(
      id: '3',
      title: 'Chaqueta de Cuero',
      description: 'Chaqueta de cuero genuino con forro interior',
      price: 129990,
      imageUrl: _defaultImage,
      rating: 4.5,
      reviewCount: 78,
      category: 'ropa',
      sellerName: 'Carlos López',
      sellerAvatar: 'https://randomuser.me/api/portraits/men/3.jpg',
    ),
    Product(
      id: '4',
      title: 'Anillo de Plata',
      description: 'Anillo de plata 925 con diseño minimalista',
      price: 35000,
      imageUrl: _defaultImage,
      rating: 4.7,
      reviewCount: 105,
      category: 'joyas',
      sellerName: 'Ana Torres',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/4.jpg',
    ),
    Product(
      id: '5',
      title: 'Set de Maquillaje',
      description:
          'Set completo de maquillaje con paleta de sombras y labiales',
      price: 45990,
      imageUrl: _defaultImage,
      rating: 4.9,
      reviewCount: 150,
      category: 'belleza',
      sellerName: 'Marta Fernández',
      sellerAvatar: 'https://randomuser.me/api/portraits/women/5.jpg',
    ),
    Product(
      id: '6',
      title: 'Lámpara Moderna',
      description: 'Lámpara de mesa con diseño contemporáneo',
      price: 39990,
      imageUrl: _defaultImage,
      rating: 4.4,
      reviewCount: 65,
      category: 'hogar',
    ),
    Product(
      id: '7',
      title: 'Audífonos Bluetooth',
      description: 'Sonido de alta calidad con cancelación de ruido',
      price: 54990,
      imageUrl: _defaultImage,
      rating: 4.3,
      reviewCount: 210,
      category: 'electronica',
    ),
    Product(
      id: '8',
      title: 'Pelota de Fútbol',
      description: 'Pelota oficial tamaño 5',
      price: 15990,
      imageUrl: _defaultImage,
      rating: 4.1,
      reviewCount: 88,
      category: 'deportes',
    ),
    Product(
      id: '9',
      title: 'Polera Estampada',
      description: 'Polera 100% algodón con diseño original',
      price: 12990,
      imageUrl: _defaultImage,
      rating: 4.2,
      reviewCount: 67,
      category: 'ropa',
    ),
    Product(
      id: '10',
      title: 'Collar de Acero',
      description: 'Collar con dije minimalista',
      price: 24990,
      imageUrl: _defaultImage,
      rating: 4.6,
      reviewCount: 50,
      category: 'joyas',
    ),
    Product(
      id: '11',
      title: 'Perfume Floral',
      description: 'Aroma fresco y duradero',
      price: 69990,
      imageUrl: _defaultImage,
      rating: 4.8,
      reviewCount: 190,
      category: 'belleza',
    ),
    Product(
      id: '12',
      title: 'Sillón Reclinable',
      description: 'Comodidad premium para tu sala de estar',
      price: 299990,
      imageUrl: _defaultImage,
      rating: 4.9,
      reviewCount: 73,
      category: 'hogar',
    ),
    Product(
      id: '13',
      title: 'Smartwatch Fit',
      description: 'Monitorea tu actividad física y salud',
      price: 89990,
      imageUrl: _defaultImage,
      rating: 4.5,
      reviewCount: 220,
      category: 'electronica',
    ),
    Product(
      id: '14',
      title: 'Raqueta de Tenis',
      description: 'Raqueta profesional ligera y resistente',
      price: 75990,
      imageUrl: _defaultImage,
      rating: 4.4,
      reviewCount: 130,
      category: 'deportes',
    ),
    Product(
      id: '15',
      title: 'Vestido de Fiesta',
      description: 'Vestido elegante para ocasiones especiales',
      price: 119990,
      imageUrl: _defaultImage,
      rating: 4.7,
      reviewCount: 140,
      category: 'ropa',
    ),
    // Productos para las nuevas categorías
    Product(
      id: '16',
      title: 'Toyota Corolla 2020',
      description: 'Automóvil en excelente estado, único dueño',
      price: 12500000,
      imageUrl: _defaultImage,
      rating: 4.8,
      reviewCount: 45,
      category: 'vehiculos',
    ),
    Product(
      id: '17',
      title: 'Casa en Las Condes',
      description: 'Casa de 3 dormitorios con jardín',
      price: 180000000,
      imageUrl: _defaultImage,
      rating: 4.9,
      reviewCount: 12,
      category: 'inmuebles',
    ),
    Product(
      id: '18',
      title: 'Cuna de Bebé',
      description: 'Cuna convertible con colchón incluido',
      price: 159990,
      imageUrl: _defaultImage,
      rating: 4.6,
      reviewCount: 78,
      category: 'bebes_ninos',
    ),
    Product(
      id: '19',
      title: 'LEGO Creator 3-en-1',
      description: 'Set de construcción para niños de 8+ años',
      price: 89990,
      imageUrl: _defaultImage,
      rating: 4.8,
      reviewCount: 156,
      category: 'juguetes',
    ),
    Product(
      id: '20',
      title: 'Taladro Inalámbrico',
      description: 'Taladro de 18V con baterías incluidas',
      price: 69990,
      imageUrl: _defaultImage,
      rating: 4.5,
      reviewCount: 89,
      category: 'herramientas',
    ),
    Product(
      id: '21',
      title: 'Casa para Perro',
      description: 'Casa resistente al agua para mascotas medianas',
      price: 49990,
      imageUrl: _defaultImage,
      rating: 4.7,
      reviewCount: 67,
      category: 'mascotas',
    ),
    Product(
      id: '22',
      title: 'Servicio de Limpieza',
      description: 'Limpieza profunda de hogar por 4 horas',
      price: 25000,
      imageUrl: _defaultImage,
      rating: 4.9,
      reviewCount: 234,
      category: 'servicios',
    ),
    Product(
      id: '23',
      title: 'Alquiler Sala de Eventos',
      description: 'Sala para 50 personas con equipamiento',
      price: 80000,
      imageUrl: _defaultImage,
      rating: 4.6,
      reviewCount: 43,
      category: 'alquileres',
    ),
  ];

  /// Lista de categorías simuladas
  final List<Category> _categories = [
    const Category(
      id: 'vehiculos',
      name: 'Vehículos',
      description: 'Autos, motos y accesorios automotrices',
      iconName: 'directions_car',
    ),
    const Category(
      id: 'inmuebles',
      name: 'Propiedades / Inmuebles',
      description: 'Compra y venta de propiedades',
      iconName: 'home',
    ),
    const Category(
      id: 'electronica',
      name: 'Electrónica',
      description: 'Gadgets, computadoras y accesorios',
      iconName: 'devices',
    ),
    const Category(
      id: 'hogar',
      name: 'Hogar y jardín',
      description: 'Muebles, decoración y jardinería',
      iconName: 'chair',
    ),
    const Category(
      id: 'ropa',
      name: 'Moda y accesorios',
      description: 'Ropa, zapatos y accesorios para todas las edades',
      iconName: 'checkroom',
    ),
    const Category(
      id: 'bebes_ninos',
      name: 'Bebés y niños',
      description: 'Productos para bebés y niños',
      iconName: 'child_care',
    ),
    const Category(
      id: 'juguetes',
      name: 'Juguetes y juegos',
      description: 'Juguetes, juegos de mesa y entretenimiento',
      iconName: 'toys',
    ),
    const Category(
      id: 'herramientas',
      name: 'Herramientas',
      description: 'Herramientas de trabajo y bricolaje',
      iconName: 'build',
    ),
    const Category(
      id: 'deportes',
      name: 'Deportes y ocio',
      description: 'Artículos deportivos y recreación',
      iconName: 'sports_soccer',
    ),
    const Category(
      id: 'mascotas',
      name: 'Mascotas y productos para animales',
      description: 'Accesorios y productos para mascotas',
      iconName: 'pets',
    ),
    const Category(
      id: 'joyas',
      name: 'Joyas',
      description: 'Accesorios y joyería',
      iconName: 'diamond',
    ),
    const Category(
      id: 'belleza',
      name: 'Belleza',
      description: 'Cosméticos y cuidado personal',
      iconName: 'spa',
    ),
    const Category(
      id: 'servicios',
      name: 'Servicios',
      description: 'Servicios profesionales y técnicos',
      iconName: 'work',
    ),
    const Category(
      id: 'alquileres',
      name: 'Alquileres',
      description: 'Alquiler de productos y espacios',
      iconName: 'apartment',
    ),
  ];

  /// Simula carga paginada
  Future<List<Product>> fetchProducts({int page = 0, int limit = 6}) async {
    await Future.delayed(const Duration(seconds: 1)); // simula red
    final start = page * limit;
    final end =
        (start + limit > _products.length) ? _products.length : start + limit;
    if (start >= _products.length) return [];
    return _products.sublist(start, end);
  }

  /// Métodos de utilidad
  List<Product> getAllProducts() => List.from(_products);

  List<Product> getProductsByCategory(String categoryId) =>
      _products.where((product) => product.category == categoryId).toList();

  List<Product> getFeaturedProducts({int limit = 4}) {
    final sortedProducts = List<Product>.from(_products)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sortedProducts.take(limit).toList();
  }

  List<Product> getFavoriteProducts() =>
      _products.where((product) => product.isFavorite).toList();

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Category> getAllCategories() => List.from(_categories);

  Category? getCategoryById(String id) {
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
