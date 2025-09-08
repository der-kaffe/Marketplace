import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Clase para gestionar los productos de la aplicación
class ProductService {
  /// Lista de productos simulados para la aplicación
  final List<Product> _products = [
    Product(
      id: '1',
      title: 'Smartphone Galaxy S23',
      description: 'Teléfono de última generación con 256GB de memoria',
      price: 699999,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.8,
      reviewCount: 120,
      category: 'electronica',
    ),
    Product(
      id: '2',
      title: 'Zapatillas Running',
      description: 'Zapatillas deportivas para running con suela amortiguada',
      price: 89990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.6,
      reviewCount: 95,
      category: 'deportes',
    ),
    Product(
      id: '3',
      title: 'Chaqueta de Cuero',
      description: 'Chaqueta de cuero genuino con forro interior',
      price: 129990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.5,
      reviewCount: 78,
      category: 'ropa',
    ),
    Product(
      id: '4',
      title: 'Anillo de Plata',
      description: 'Anillo de plata 925 con diseño minimalista',
      price: 35000,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.7,
      reviewCount: 105,
      category: 'joyas',
    ),
    Product(
      id: '5',
      title: 'Set de Maquillaje',
      description: 'Set completo de maquillaje con paleta de sombras y labiales',
      price: 45990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.9,
      reviewCount: 150,
      category: 'belleza',
    ),
    Product(
      id: '6',
      title: 'Lámpara Moderna',
      description: 'Lámpara de mesa con diseño contemporáneo',
      price: 39990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.4,
      reviewCount: 65,
      category: 'hogar',
    ),
    Product(
      id: '7',
      title: 'Audífonos Bluetooth',
      description: 'Sonido de alta calidad con cancelación de ruido',
      price: 54990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.3,
      reviewCount: 210,
      category: 'electronica',
    ),
    Product(
      id: '8',
      title: 'Pelota de Fútbol',
      description: 'Pelota oficial tamaño 5',
      price: 15990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.1,
      reviewCount: 88,
      category: 'deportes',
    ),
    Product(
      id: '9',
      title: 'Polera Estampada',
      description: 'Polera 100% algodón con diseño original',
      price: 12990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.2,
      reviewCount: 67,
      category: 'ropa',
    ),
    Product(
      id: '10',
      title: 'Collar de Acero',
      description: 'Collar con dije minimalista',
      price: 24990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.6,
      reviewCount: 50,
      category: 'joyas',
    ),
    Product(
      id: '11',
      title: 'Perfume Floral',
      description: 'Aroma fresco y duradero',
      price: 69990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.8,
      reviewCount: 190,
      category: 'belleza',
    ),
    Product(
      id: '12',
      title: 'Sillón Reclinable',
      description: 'Comodidad premium para tu sala de estar',
      price: 299990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.9,
      reviewCount: 73,
      category: 'hogar',
    ),
    Product(
      id: '13',
      title: 'Smartwatch Fit',
      description: 'Monitorea tu actividad física y salud',
      price: 89990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.5,
      reviewCount: 220,
      category: 'electronica',
    ),
    Product(
      id: '14',
      title: 'Raqueta de Tenis',
      description: 'Raqueta profesional ligera y resistente',
      price: 75990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.4,
      reviewCount: 130,
      category: 'deportes',
    ),
    Product(
      id: '15',
      title: 'Vestido de Fiesta',
      description: 'Vestido elegante para ocasiones especiales',
      price: 119990,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.7,
      reviewCount: 140,
      category: 'ropa',
    ),
  ];

  /// Lista de categorías simuladas
  final List<Category> _categories = [
    const Category(
      id: 'deportes',
      name: 'Deportes',
      description: 'Artículos deportivos y equipamiento',
      iconName: 'sports_soccer',
    ),
    const Category(
      id: 'electronica',
      name: 'Electrónica',
      description: 'Gadgets, computadoras y accesorios',
      iconName: 'devices',
    ),
    const Category(
      id: 'ropa',
      name: 'Ropa',
      description: 'Moda para todas las edades',
      iconName: 'checkroom',
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
      id: 'hogar',
      name: 'Hogar',
      description: 'Muebles y decoración',
      iconName: 'chair',
    ),
  ];

  /// Simula carga paginada
  Future<List<Product>> fetchProducts({int page = 0, int limit = 6}) async {
    await Future.delayed(const Duration(seconds: 1)); // simula red
    final start = page * limit;
    final end = (start + limit > _products.length) ? _products.length : start + limit;
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
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'devices':
        return Icons.devices;
      case 'checkroom':
        return Icons.checkroom;
      case 'diamond':
        return Icons.diamond;
      case 'spa':
        return Icons.spa;
      case 'chair':
        return Icons.chair;
      default:
        return Icons.category;
    }
  }
}
