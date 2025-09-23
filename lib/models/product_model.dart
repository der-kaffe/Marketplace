/// Modelo para representar un producto en la aplicación
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String category;
  final bool isAvailable;
  final bool isFavorite;

  // 👤 Nuevo: datos del vendedor
  final String? sellerName;
  final String? sellerAvatar;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.category,
    this.isAvailable = true,
    this.isFavorite = false,
    this.sellerName,
    this.sellerAvatar,
  });

  /// Crea una copia del producto con algunos campos modificados
  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    String? category,
    bool? isAvailable,
    bool? isFavorite,
    String? sellerName,
    String? sellerAvatar,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isFavorite: isFavorite ?? this.isFavorite,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
    );
  }

  /// Convierte el producto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'isAvailable': isAvailable,
      'isFavorite': isFavorite,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
    };
  }

  /// Crea un producto desde JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as int?) ?? 0,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      sellerName: json['sellerName'] as String?,
      sellerAvatar: json['sellerAvatar'] as String?,
    );
  }
}

/// Modelo para representar una categoría de productos
class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.iconName,
  });

  /// Convierte la categoría a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
    };
  }

  /// Crea una categoría desde JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      iconName: json['iconName'] as String,
    );
  }
}
