import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/product_model.dart' as ProductModel;

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

  // ✅ NUEVO: Obtener productos reales de la BD
  Future<ProductsResponse> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
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
      
      print('🔍 Obteniendo productos de: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductsResponse.fromJson(data);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ✅ NUEVO: Obtener producto por ID
  Future<ProductDetailResponse> getProductById(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductDetailResponse.fromJson(data);
      } else {
        throw Exception('Producto no encontrado');
      }
    } catch (e) {
      throw Exception('Error obteniendo producto: $e');
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

  // FAVORITES ENDPOINTS

  // ✅ Métodos de favoritos existentes (ya funcionan)
  Future<FavoritesResponse> getProductFavorites({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites?page=$page&limit=$limit'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FavoritesResponse.fromJson(data);
      } else {
        throw Exception('Error obteniendo favoritos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Agregar producto a favoritos
  Future<void> addProductFavorite({required int productoId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites'),
        headers: _headers,
        body: json.encode({'productoId': productoId}),
      );
      
      if (response.statusCode != 201) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Error agregando favorito');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ✅ CORREGIDO: Eliminar producto de favoritos
  Future<void> removeProductFavorite({required int productoId}) async {
    try {
      // 🔧 CAMBIO: Enviar productoId como parámetro de URL, no en body
      final response = await http.delete(
        Uri.parse('$baseUrl/api/favorites/$productoId'), // ✅ En la URL
        headers: _headers,
        // ❌ REMOVER: body con JSON
      );
      
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Error eliminando favorito');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
  final String apellido;    // ✏️ Editable
  final String role;        // 🔒 Solo lectura (sistema)
  final String usuario;     // ✏️ Editable
  final String campus;     // ✏️ Editable
  final String? telefono;   // ✏️ Editable
  final String? direccion;  // ✏️ Editable

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.apellido = '',
    this.usuario = '',
    this.campus = 'Campus Temuco',
    this.telefono = '',
    this.direccion = '',
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
      telefono: json['telefono'] ?? '',
      direccion: json['direccion'] ?? '',
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

// ✅ NUEVOS: Modelos para productos reales
class ProductsResponse {
  final bool ok;
  final List<ProductFromDB> products;
  final PaginationInfo pagination;

  ProductsResponse({
    required this.ok,
    required this.products,
    required this.pagination,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      ok: json['ok'] ?? false,
      products: (json['products'] as List<dynamic>?)
          ?.map((item) => ProductFromDB.fromJson(item))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class ProductDetailResponse {
  final bool ok;
  final ProductFromDB product;

  ProductDetailResponse({
    required this.ok,
    required this.product,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      ok: json['ok'] ?? false,
      product: ProductFromDB.fromJson(json['product']),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

// ✅ NUEVO: Modelo para productos de la BD (renombrado para evitar conflictos)
class ProductFromDB {
  final int id;
  final String nombre;
  final String? descripcion;
  final double? precioAnterior;
  final double? precioActual;
  final String? categoria;
  final double? calificacion;
  final int? cantidad;
  final String estado;
  final DateTime fechaAgregado;
  final List<dynamic> imagenes; // Bytes de imágenes
  final VendedorFromDB vendedor;

  ProductFromDB({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precioAnterior,
    this.precioActual,
    this.categoria,
    this.calificacion,
    this.cantidad,
    required this.estado,
    required this.fechaAgregado,
    required this.imagenes,
    required this.vendedor,
  });

  factory ProductFromDB.fromJson(Map<String, dynamic> json) {
    // ✅ Función helper para convertir números de forma segura
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    int? safeToInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    DateTime safeParseDatetime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ProductFromDB(
      id: safeToInt(json['id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precioAnterior: safeToDouble(json['precioAnterior']),
      precioActual: safeToDouble(json['precioActual']),
      categoria: json['categoria']?.toString(),
      calificacion: safeToDouble(json['calificacion']),
      cantidad: safeToInt(json['cantidad']),
      estado: json['estado']?.toString() ?? '',
      fechaAgregado: safeParseDatetime(json['fechaAgregado']),
      imagenes: json['imagenes'] ?? [],
      vendedor: VendedorFromDB.fromJson(json['vendedor'] ?? {}),
    );
  }

  // ✅ Convertir a modelo ProductModel.Product para compatibilidad
  ProductModel.Product toProductModel() {
    return ProductModel.Product(
      id: id.toString(),
      title: nombre,
      description: descripcion ?? 'Sin descripción',
      price: precioActual ?? 0.0,
      imageUrl: _getImageUrl(), // Manejar imágenes como bytes o placeholder
      rating: calificacion ?? 0.0,
      reviewCount: 0, // Por ahora
      category: categoria ?? 'Sin categoría',
      isAvailable: estado == 'Disponible',
      sellerId: vendedor.id.toString(),
      sellerName: '${vendedor.nombre} ${vendedor.apellido ?? ''}',
      sellerAvatar: null, // Por ahora
    );
  }

  String? _getImageUrl() {
    // Por ahora, como las imágenes están como Bytes en la BD,
    // usaremos el placeholder hasta implementar la conversión
    if (imagenes.isNotEmpty) {
      // Aquí luego implementaremos la conversión de Bytes a base64 o URL
      return null; // Usará el placeholder por defecto
    }
    return null;
  }
}

class VendedorFromDB {
  final int id;
  final String nombre;
  final String? apellido;
  final String correo;
  final String? campus;
  final double reputacion;

  VendedorFromDB({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    this.campus,
    required this.reputacion,
  });

  factory VendedorFromDB.fromJson(Map<String, dynamic> json) {
    // ✅ Función helper para conversión segura
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return VendedorFromDB(
      id: safeToInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
      correo: json['correo']?.toString() ?? '',
      campus: json['campus']?.toString(),
      reputacion: safeToDouble(json['reputacion']),
    );
  }
}

// ✅ Modelos existentes de favoritos
class FavoritesResponse {
  final bool ok;
  final List<FavoritedProduct> favorites;

  FavoritesResponse({required this.ok, required this.favorites});

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      ok: json['ok'] ?? false,
      favorites: (json['favorites'] as List<dynamic>?)
          ?.map((item) => FavoritedProduct.fromJson(item))
          .toList() ?? [],
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