import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({required this.baseUrl});

  // Configurar token de autenticación
  void setToken(String token) {
    _token = token;
  }

  // Eliminar token
  void clearToken() {
    _token = null;
  }

  // Headers comunes
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Manejo de respuestas
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        message: body['message'] ?? 'Error desconocido',
        statusCode: response.statusCode,
        errors: body['errors'],
      );
    }
  }

  // Health check
  Future<Map<String, dynamic>> health() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException(message: 'Error de conexión: $e');
    }
  }

  // AUTH ENDPOINTS

  // Login con email y password
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = _handleResponse(response);
      return LoginResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Registro
  Future<LoginResponse> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );
      
      final data = _handleResponse(response);
      return LoginResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Login con Google
  Future<LoginResponse> loginWithGoogle({
    required String idToken,
    required String email,
    required String name,
    String? googleId,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: _headers,
        body: json.encode({
          'idToken': idToken,
          'email': email,
          'name': name,
          'googleId': googleId,
          'avatarUrl': avatarUrl,
        }),
      );
      
      final data = _handleResponse(response);
      return LoginResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // USER ENDPOINTS
  // Obtener perfil del usuario actual
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar campos editables del perfil
  Future<Map<String, dynamic>> updateProfile({
    String? apellido,
    String? usuario,
    String? campus,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (apellido != null) body['apellido'] = apellido;
      if (usuario != null) body['usuario'] = usuario;
      if (campus != null) body['campus'] = campus;
      if (telefono != null) body['telefono'] = telefono;
      if (direccion != null) body['direccion'] = direccion;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: _headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // PRODUCT ENDPOINTS

  // Listar productos
  Future<ProductsResponse> getProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      
      final uri = Uri.parse('$baseUrl/api/products').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: _headers);
      final data = _handleResponse(response);
      return ProductsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener producto por ID
  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Crear producto
  Future<Map<String, dynamic>> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    String? conditionType,
    List<String>? images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'condition_type': conditionType ?? 'used',
          'images': images ?? [],
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener categorías
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/categories/list'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return (data['categories'] as List)
          .map((cat) => Category.fromJson(cat))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // FAVORITES ENDPOINTS

  // Obtener favoritos del usuario
  Future<FavoritesResponse> getProductFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('$baseUrl/api/favorites').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: _headers);
      final data = _handleResponse(response);
      return FavoritesResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Agregar producto a favoritos
  Future<Map<String, dynamic>> addProductFavorite({required int productoId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites'),
        headers: _headers,
        body: json.encode({
          'productoId': productoId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar producto de favoritos
  Future<Map<String, dynamic>> removeProductFavorite({required int productoId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/favorites/$productoId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

// Helper para obtener la URL base según la plataforma
String getDefaultBaseUrl() {
  if (kIsWeb) {
    // Para web: usar localhost
    return 'http://localhost:3001';
  } else {
    // Para Android emulador: usar 10.0.2.2
    // Para dispositivo físico: usar la IP de tu computadora
    return 'http://10.0.2.2:3001';
  }
}

// Modelos de respuesta
class LoginResponse {
  final bool ok;
  final String message;
  final String? token;
  final User? user;

  LoginResponse({
    required this.ok,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final int id;
  final String email;     // 🔒 Solo lectura (de Google)
  final String name;      // 🔒 Solo lectura (de Google)
  final String role;      // 🔒 Solo lectura (sistema)
  final String apellido;  // ✏️ Editable
  final String usuario;   // ✏️ Editable
  final String campus;    // ✏️ Editable
  final String? telefono; // ✏️ Editable (opcional)
  final String? direccion;// ✏️ Editable (opcional)

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.apellido = '',
    this.usuario = '',
    this.campus = 'Campus Temuco',
    this.telefono,
    this.direccion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['correo'] ?? json['email'] ?? '',
      name: json['nombre'] ?? json['name'] ?? '',
      role: json['role'] ?? 'Cliente', // Por defecto Cliente para Google login
      apellido: json['apellido'] ?? '',
      usuario: json['usuario'] ?? '',
      campus: json['campus'] ?? 'Campus Temuco',
      telefono: json['telefono'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': email,
      'nombre': name,
      'role': role,
      'apellido': apellido,
      'usuario': usuario,
      'campus': campus,
      'telefono': telefono,
      'direccion': direccion,
    };
  }
}

class ProductsResponse {
  final bool ok;
  final List<Product> products;
  final Pagination pagination;

  ProductsResponse({
    required this.ok,
    required this.products,
    required this.pagination,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      ok: json['ok'] ?? false,
      products: (json['products'] as List? ?? [])
          .map((p) => Product.fromJson(p))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String conditionType;
  final List<String> images;
  final bool isAvailable;
  final bool isFeatured;
  final DateTime createdAt;
  final String sellerName;
  final String sellerEmail;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.conditionType,
    required this.images,
    required this.isAvailable,
    required this.isFeatured,
    required this.createdAt,
    required this.sellerName,
    required this.sellerEmail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'],
      conditionType: json['condition_type'],
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : [],
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      sellerName: json['seller_name'] ?? '',
      sellerEmail: json['seller_email'] ?? '',
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}

// Respuesta de favoritos
class FavoritesResponse {
  final bool ok;
  final List<FavoritedProduct> favorites;
  final Pagination pagination;

  FavoritesResponse({
    required this.ok,
    required this.favorites,
    required this.pagination,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      ok: json['ok'] ?? false,
      favorites: (json['favorites'] as List? ?? [])
          .map((f) => FavoritedProduct.fromJson(f))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

// Producto favorito
class FavoritedProduct {
  final int id;
  final int usuarioId;
  final int productoId;
  final DateTime fecha;
  final String nombre;
  final String? categoria;
  final double? precioActual;
  final String vendedorNombre;

  FavoritedProduct({
    required this.id,
    required this.usuarioId,
    required this.productoId,
    required this.fecha,
    required this.nombre,
    this.categoria,
    this.precioActual,
    required this.vendedorNombre,
  });

  factory FavoritedProduct.fromJson(Map<String, dynamic> json) {
    // Adaptamos para manejar tanto la estructura directa como anidada
    final producto = json['producto'];
    final vendedor = producto?['vendedor'];
    
    return FavoritedProduct(
      id: json['id'],
      usuarioId: json['usuarioId'] ?? json['usuario_id'],
      productoId: json['productoId'] ?? json['producto_id'],
      fecha: DateTime.parse(json['fecha']),
      nombre: producto?['nombre'] ?? json['nombre'] ?? '',
      categoria: producto?['categoria']?['nombre'] ?? json['categoria'],
      precioActual: producto?['precioActual'] != null 
          ? double.tryParse(producto['precioActual'].toString())
          : null,
      vendedorNombre: vendedor?['nombre'] ?? json['vendedorNombre'] ?? '',
    );
  }
}

// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}
