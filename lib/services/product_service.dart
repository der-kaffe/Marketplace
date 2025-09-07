import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Clase para gestionar los productos de la aplicación
class ProductService {
  /// Lista de productos simulados para la aplicación  final List<Product> _products = [
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

  /// Obtiene todos los productos disponibles
  List<Product> getAllProducts() {
    return List.from(_products);
  }

  /// Obtiene productos por categoría
  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((product) => product.category == categoryId).toList();
  }

  /// Obtiene productos destacados (con mayor rating)
  List<Product> getFeaturedProducts({int limit = 4}) {
    final sortedProducts = List<Product>.from(_products)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sortedProducts.take(limit).toList();
  }

  /// Obtiene productos favoritos (simulado)
  List<Product> getFavoriteProducts() {
    return _products.where((product) => product.isFavorite).toList();
  }

  /// Obtiene un producto por su ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las categorías
  List<Category> getAllCategories() {
    return List.from(_categories);
  }

  /// Obtiene una categoría por su ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
  /// Convierte un nombre de icono a un widget Icon
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
