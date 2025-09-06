import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Clase para gestionar los productos de la aplicación
class ProductService {
  /// Lista de productos simulados para la aplicación
  final List<Product> _products = [
    Product(
      id: '1',
      title: 'Sandwich Italiano',
      description: 'Delicioso sandwich con palta, tomate y mayonesa',
      price: 2500,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.5,
      reviewCount: 120,
      category: 'comidas',
    ),
    Product(
      id: '2',
      title: 'Café Americano',
      description: 'Café recién molido, fuerte y aromático',
      price: 1800,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.8,
      reviewCount: 95,
      category: 'bebidas',
    ),
    Product(
      id: '3',
      title: 'Ensalada César',
      description: 'Ensalada fresca con lechuga, pollo, crutones y aderezo especial',
      price: 3200,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.3,
      reviewCount: 78,
      category: 'comidas',
    ),
    Product(
      id: '4',
      title: 'Jugo Natural',
      description: 'Jugo de frutas naturales sin azúcar añadida',
      price: 1500,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.7,
      reviewCount: 105,
      category: 'bebidas',
    ),
    Product(
      id: '5',
      title: 'Brownie de Chocolate',
      description: 'Delicioso brownie casero con trozos de chocolate',
      price: 1200,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.9,
      reviewCount: 150,
      category: 'postres',
    ),
    Product(
      id: '6',
      title: 'Galletas de Avena',
      description: 'Galletas de avena con pasas, suaves por dentro y crocantes por fuera',
      price: 800,
      imageUrl: 'https://via.placeholder.com/150',
      rating: 4.4,
      reviewCount: 65,
      category: 'snacks',
    ),
  ];

  /// Lista de categorías simuladas
  final List<Category> _categories = [
    const Category(
      id: 'comidas',
      name: 'Comidas',
      description: 'Sandwiches, ensaladas y más',
      iconName: 'fastfood',
    ),
    const Category(
      id: 'bebidas',
      name: 'Bebidas',
      description: 'Cafés, jugos y bebidas frías',
      iconName: 'local_drink',
    ),
    const Category(
      id: 'snacks',
      name: 'Snacks',
      description: 'Opciones para picar entre comidas',
      iconName: 'breakfast_dining',
    ),
    const Category(
      id: 'postres',
      name: 'Postres',
      description: 'Dulces y postres variados',
      iconName: 'cake',
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
      case 'fastfood':
        return Icons.fastfood;
      case 'local_drink':
        return Icons.local_drink;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'cake':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }
}
