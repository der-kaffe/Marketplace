// lib/services/api_client.dart

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

  Future<Map<String, dynamic>> reportProduct({
    required int productId, // ✅ CAMBIAR nombre del parámetro
    required String motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reports/product'),
        headers: _headers,
        body: json.encode({
          'productId': productId, // ✅ USAR productId
          'motivo': motivo,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(message: 'Error reportando producto: $e');
    }
  }

  Future<Map<String, dynamic>> reportUser({
    required int userId, // ✅ CAMBIAR nombre del parámetro
    required String motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reports/user'),
        headers: _headers,
        body: json.encode({
          'userId': userId, // ✅ USAR userId
          'motivo': motivo,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(message: 'Error reportando usuario: $e');
    }
  }

  Future<List<dynamic>> getMyReports(String token) async {
    final url = Uri.parse('$baseUrl/api/reports/my-reports');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reportes'] ?? [];
    } else {
      throw Exception('Error al obtener mis reportes: ${response.statusCode}');
    }
  }

  // Obtener estados de reporte disponibles
  Future<List<ReportStatus>> getReportStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reports/estados/list'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final estados = (data['estados'] as List)
            .map((e) => ReportStatus.fromJson(e))
            .toList();
        return estados;
      } else {
        throw Exception('Error obteniendo estados');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> saveFcmToken(String fcmToken) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile/fcm-token'),
        headers: _headers, // Usa los headers de autenticación
        body: json.encode({
          'fcmToken': fcmToken,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // NUEVO: Obtener los productos del usuario autenticado
  Future<ProductsResponse> getMyProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/products/my-products').replace(
        queryParameters: queryParams,
      );

      print('🔍 Obteniendo mis productos de: $uri');

      final response = await http.get(uri, headers: _headers);
      final data = _handleResponse(response);
      return ProductsResponse.fromJson(data);
    } catch (e) {
      print('❌ Error obteniendo mis productos: $e');
      rethrow;
    }
  }

  // --- NUEVO: Método para obtener categorías desde la API ---
  Future<List<ProductModel.ApiCategory>> getCategoriesFromApi() async {
    try {
      // ✅ CORREGIDO: URL completa con el prefijo /publications
      final uri = Uri.parse('$baseUrl/api/publications/get_categorias');

      print('🔍 Obteniendo categorías de: $uri');

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['categorias'] is List) {
          final categoriasJson = data['categorias'] as List;
          return categoriasJson
              .map((json) => ProductModel.ApiCategory.fromJson(json))
              .toList();
        } else {
          throw Exception(
              'API no devolvió categorías válidas o "ok" no es true');
        }
      } else {
        throw Exception(
            'Error del servidor al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo categorías desde API: $e');
      rethrow; // Re-lanza la excepción para que el UI pueda manejarla
    }
  }
  // --- FIN NUEVO ---

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
  Future<LoginResponse> register(
      String email, String password, String name) async {
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
    String? name, // ✅ AGREGAR name
    String? apellido,
    String? usuario,
    String? campus,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name; // ✅ AGREGAR
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

  Future<Map<String, dynamic>> rateSeller({
    required int sellerId,
    required int rating, // ✅ CAMBIAR nombre del parámetro
    String? comment, // ✅ CAMBIAR nombre del parámetro
  }) async {
    print('🔍 ApiClient.rateSeller - Parámetros:');
    print('   sellerId: $sellerId');
    print('   rating: $rating'); // ✅ ACTUALIZAR
    print('   comment: $comment'); // ✅ ACTUALIZAR
    print('   token actual: $_token');

    final url = Uri.parse('$baseUrl/api/users/rate/$sellerId');
    print('   URL completa: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'puntuacion': rating, // ✅ CAMBIAR de puntuacion a rating
        'comentario': comment ?? '', // ✅ CAMBIAR de comentario a comment
      }),
    );

    print('   📡 Response status: ${response.statusCode}');
    print('   📡 Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      print('   ✅ Response: $data');
      return data;
    } else {
      print('   ❌ Error HTTP: ${response.statusCode}');
      print('   ❌ Response body: ${response.body}');

      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Error desconocido';
        final errorCode = errorBody['error']?['code'] ?? 'UNKNOWN_ERROR';

        print('   ❌ Error code: $errorCode');
        print('   ❌ Error message: $errorMessage');

        throw Exception('ERROR_CODE:$errorCode:$errorMessage');
      } catch (e) {
        if (e.toString().contains('ERROR_CODE:')) {
          print('   ✅ Error con formato correcto, propagando: $e');
          rethrow;
        }

        print('   ❌ Error parsing response body: $e');
        throw Exception('Error al calificar vendedor: ${response.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> getSellerRatings(int sellerId) async {
    final url = Uri.parse('$baseUrl/api/users/$sellerId/ratings');
    final response = await http.get(url, headers: _headers);
    return _handleResponse(response);
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

  // Crear producto (VERIFICADO)
  Future<Map<String, dynamic>> createProduct({
    required String nombre,
    required String descripcion,
    required double precioActual,
    required int categoriaId,
    double? precioAnterior,
    int? cantidad,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: _headers,
        body: json.encode({
          'nombre': nombre,
          'descripcion': descripcion,
          'precioActual': precioActual,
          'categoriaId': categoriaId,
          'precioAnterior': precioAnterior,
          'cantidad': cantidad ?? 1,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ NUEVO: Inicia una transacción de compra
  Future<Map<String, dynamic>> createTransaction({
    required int productId,
    required int quantity,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/transactions');
      print('🛒 Creando transacción: POST $uri');
      final response = await http.post(
        uri,
        headers: _headers, // Usa los headers con token
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
        }),
      );

      print('   -> Respuesta: ${response.statusCode}');
      // Usamos _handleResponse que ya maneja errores 4xx/5xx
      return _handleResponse(response);

    } catch (e) {
      print('❌ Excepción en createTransaction: $e');
      // Re-lanzar como ApiException si no lo es ya
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Error de conexión al crear transacción: $e');
    }
  }

  // --- MÉTODOS PARA TRANSACCIONES Y CONFIRMACIÓN ---

  /// Obtiene la lista de compras del usuario actual
  Future<TransactionListResponse> getMyPurchases({int page = 1, int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/transactions/purchases').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      print('🛍️ Obteniendo mis compras: GET $uri');
      final response = await http.get(uri, headers: _headers);
      final data = _handleResponse(response);
      return TransactionListResponse.fromJsonPurchases(data);
    } catch (e) {
      print('❌ Excepción en getMyPurchases: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error de conexión al obtener compras: $e');
    }
  }

  /// Obtiene la lista de ventas del usuario actual
  Future<TransactionListResponse> getMySales({int page = 1, int limit = 10}) async {
    try {
       final uri = Uri.parse('$baseUrl/api/transactions/sales').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      print('💰 Obteniendo mis ventas: GET $uri');
      final response = await http.get(uri, headers: _headers);
       final data = _handleResponse(response);
      return TransactionListResponse.fromJsonSales(data);
    } catch (e) {
       print('❌ Excepción en getMySales: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error de conexión al obtener ventas: $e');
    }
  }

  /// Vendedor confirma la entrega de una transacción
  Future<Map<String, dynamic>> confirmDelivery(int transactionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/transactions/$transactionId/confirm-delivery');
      print('🚚 Confirmando entrega (Vendedor): PATCH $uri');
      final response = await http.patch(uri, headers: _headers);
      print('   -> Respuesta: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Excepción en confirmDelivery: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error de conexión al confirmar entrega: $e');
    }
  }

  /// Comprador confirma el recibo de una transacción
  Future<Map<String, dynamic>> confirmReceipt(int transactionId) async {
     try {
      final uri = Uri.parse('$baseUrl/api/transactions/$transactionId/confirm-receipt');
      print('🤝 Confirmando recibo (Comprador): PATCH $uri');
      final response = await http.patch(uri, headers: _headers);
      print('   -> Respuesta: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Excepción en confirmReceipt: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error de conexión al confirmar recibo: $e');
    }
  }


  // ============================================================================
  // MÉTODOS ADICIONALES DE PRODUCTOS Y USUARIOS
  // ============================================================================

  /// Actualizar visibilidad de un producto (admin/vendedor)
  Future<void> updateProductVisibility(int productId, bool visible) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/products/$productId/visibility'),
        headers: _headers,
        body: json.encode({'visible': visible}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body =
            response.body.isNotEmpty ? json.decode(response.body) : null;
        final message =
            body != null ? (body['message'] ?? response.body) : response.body;
        throw ApiException(
          message: 'Error actualizando visibilidad: $message',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener información de un usuario por ID
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$userId');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw ApiException(
          message: 'Usuario no encontrado',
          statusCode: response.statusCode,
        );
      }
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

  // 🔥 NUEVO: Eliminar producto
  Future<void> deleteProduct(int productId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/products/$productId');
      final response = await http.delete(uri, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Producto $productId eliminado correctamente');
        return;
      } else {
        print('❌ Error al eliminar producto: ${response.statusCode}');
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw ApiException(
          message: body['message'] ?? 'Error al eliminar producto',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Excepción al eliminar producto: $e');
      throw ApiException(message: 'Error de conexión: $e');
    }
  }

  // 🔥 NUEVO: Actualizar producto
  Future<Map<String, dynamic>> updateProduct(
      int productId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/products/$productId');
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Producto actualizado correctamente');
        return jsonDecode(response.body);
      } else {
        print('❌ Error actualizando producto: ${response.statusCode}');
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw ApiException(
          message: body['message'] ?? 'Error al actualizar producto',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Excepción en updateProduct: $e');
      throw ApiException(message: 'Error de conexión: $e');
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
  final String email;
  final String name;
  final int? rolId;
  final String? role;
  final String? apellido;
  final String? usuario;
  final String? campus;
  final String? telefono;
  final String? direccion;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.rolId,
    this.role,
    this.apellido,
    this.usuario,
    this.campus,
    this.telefono,
    this.direccion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['correo'] ?? json['email'] ?? '',
      name: json['nombre'] ?? json['name'] ?? '',
      rolId: json['rolId'] ?? json['rol_id'],
      role: json['rol']?['nombre'] ?? json['role'], // ✅ soporta backend Prisma
      apellido: json['apellido'],
      usuario: json['usuario'],
      campus: json['campus'],
      telefono: json['telefono'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'correo': email,
        'nombre': name,
        'rolId': rolId,
        'role': role,
        'apellido': apellido,
        'usuario': usuario,
        'campus': campus,
        'telefono': telefono,
        'direccion': direccion,
      };

  bool get isAdmin =>
      (rolId == 1) || ((role?.toUpperCase() ?? '') == 'ADMINISTRADOR');
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
              .toList() ??
          [],
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
  final String? categoria; // Campo de categoría (nombre)
  final String? categoriaId; // Campo de categoría (ID) - Añadir si la API lo devuelve
  final double? calificacion;
  final int? cantidad;
  final String estado;
  final DateTime fechaAgregado;
  final List<dynamic> imagenes; // Bytes de imágenes
  final VendedorFromDB vendedor;
  final bool? visible; // ✅ Añadido campo visible

  ProductFromDB({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precioAnterior,
    this.precioActual,
    this.categoria,
    this.categoriaId,
    this.calificacion,
    this.cantidad,
    required this.estado,
    required this.fechaAgregado,
    required this.imagenes,
    required this.vendedor,
    required this.visible, // ✅ Añadido al constructor
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

    // Helper para booleanos
    bool safeToBool(dynamic value, {bool defaultValue = true}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return defaultValue;
    }

    // ✅ NUEVA LÓGICA MÁS SEGURA PARA CATEGORÍA Y ESTADO
    String? categoriaNombre;
    String? categoriaIdStr;
    dynamic categoriaJson = json['categoria'];
    if (categoriaJson is Map) {
      categoriaNombre = categoriaJson['nombre']?.toString();
      categoriaIdStr = categoriaJson['id']?.toString();
    } else if (categoriaJson is String) {
      categoriaNombre = categoriaJson;
      // No podemos obtener el ID si solo viene el nombre
    }
    // Si la API envía 'categoriaId' directamente, úsalo como fallback si no lo obtuvimos del objeto anidado
    categoriaIdStr ??= json['categoriaId']?.toString();


    String estadoNombre = '';
    dynamic estadoJson = json['estado'];
    if (estadoJson is Map) {
      estadoNombre = estadoJson['nombre']?.toString() ?? '';
    } else if (estadoJson is String) {
      estadoNombre = estadoJson;
    }

    return ProductFromDB(
      id: safeToInt(json['id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precioAnterior: safeToDouble(json['precioAnterior']),
      precioActual: safeToDouble(json['precioActual']),

      // ✅ USA LOS VALORES PROCESADOS
      categoria: categoriaNombre,
      categoriaId: categoriaIdStr,

      calificacion: safeToDouble(json['calificacion']),
      cantidad: safeToInt(json['cantidad']),

      // ✅ USA EL VALOR PROCESADO
      estado: estadoNombre,

      fechaAgregado: safeParseDatetime(json['fechaAgregado']),
      imagenes: json['imagenes'] ?? [],
      vendedor: VendedorFromDB.fromJson(json['vendedor'] ?? {}),
      visible: safeToBool(json['visible'], defaultValue: true),
    );
  }

  ProductModel.Product toProductModel() {
    print('--- DEBUG ProductFromDB.toProductModel ---');
    print('ID Producto: ${id}');
    print('Nombre Producto: ${nombre}');
    print('Categoria Nombre (RAW): ${categoria}');
    print('Categoria ID (RAW): ${categoriaId}');
    print('Cantidad (RAW): ${cantidad}'); // 👈 Añadí este print para verificar
    print('-----------------------------');

    // Usar categoriaId como el identificador para el filtro si está disponible y es numérico
    // Convertirlo a String para que coincida con el tipo del campo 'category' en ProductModel.Product
    String categoryIdentifier = categoriaId != null
        ? categoriaId.toString()
        : (categoria ?? 'Sin categoría');
    print(
        'CategoryIdentifier asignado: $categoryIdentifier (tipo: ${categoryIdentifier.runtimeType})'
    );

    return ProductModel.Product(
      id: id.toString(),
      title: nombre,
      description: descripcion ?? 'Sin descripción',
      price: precioActual ?? 0.0,
      imageUrl: _getImageUrl(),
      rating: calificacion ?? 0.0,
      reviewCount: 0, 
      category: categoryIdentifier,
      isAvailable: this.visible ?? true, 
      cantidad: cantidad ?? 0,
      sellerId: vendedor.id.toString(),
      sellerName: '${vendedor.nombre} ${vendedor.apellido ?? ''}'.trim(), // Trim para quitar espacios extra
      sellerAvatar: vendedor.avatarUrl, // ✅ Usar el avatar del vendedor si existe
      sellerEmail: vendedor.correo,
    );
  }

  String? _getImageUrl() {
    if (imagenes.isNotEmpty) {
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
  final String? avatarUrl; // 👈 AÑADE ESTO SI TU API LO DEVUELVE

  VendedorFromDB({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    this.campus,
    required this.reputacion,
    this.avatarUrl, // 👈 AÑADE ESTO
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
      avatarUrl: json['avatar']?.toString(), // 👈 AÑADE ESTO
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
              .toList() ??
          [],
    );
  }
}

class ReportsResponse {
  final bool ok;
  final List<Report> reportes;
  final PaginationInfo pagination;

  ReportsResponse({
    required this.ok,
    required this.reportes,
    required this.pagination,
  });

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    return ReportsResponse(
      ok: json['ok'] ?? false,
      reportes: (json['reportes'] as List<dynamic>?)
              ?.map((item) => Report.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

// Modelo de reporte
class Report {
  final int id;
  final String motivo;
  final DateTime fecha;
  final int? productoId;
  final int? usuarioReportadoId;
  final String estado;
  final ProductReportInfo? producto;
  final UserReportInfo? usuarioReportado;

  Report({
    required this.id,
    required this.motivo,
    required this.fecha,
    this.productoId,
    this.usuarioReportadoId,
    required this.estado,
    this.producto,
    this.usuarioReportado,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      motivo: json['motivo'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      productoId: json['productoId'],
      usuarioReportadoId: json['usuarioReportadoId'],
      estado: json['estado']?['nombre'] ?? 'Pendiente',
      producto: json['producto'] != null
          ? ProductReportInfo.fromJson(json['producto'])
          : null,
      usuarioReportado: json['usuarioReportado'] != null
          ? UserReportInfo.fromJson(json['usuarioReportado'])
          : null,
    );
  }
}

// Info de producto en reporte
class ProductReportInfo {
  final int id;
  final String nombre;

  ProductReportInfo({
    required this.id,
    required this.nombre,
  });

  factory ProductReportInfo.fromJson(Map<String, dynamic> json) {
    return ProductReportInfo(
      id: json['id'],
      nombre: json['nombre'] ?? '',
    );
  }
}

// Info de usuario en reporte
class UserReportInfo {
  final int id;
  final String nombre;
  final String? apellido;

  UserReportInfo({
    required this.id,
    required this.nombre,
    this.apellido,
  });

  factory UserReportInfo.fromJson(Map<String, dynamic> json) {
    return UserReportInfo(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'],
    );
  }
}

// Estados de reporte
class ReportStatus {
  final int id;
  final String nombre;

  ReportStatus({
    required this.id,
    required this.nombre,
  });

  factory ReportStatus.fromJson(Map<String, dynamic> json) {
    return ReportStatus(
      id: json['id'],
      nombre: json['nombre'] ?? '',
    );
  }
}

// Producto favorito
class FavoritedProduct {
  final int id;
  final int usuarioId;
  final int productoId;
  final DateTime fecha;
  final String nombre; // ✅ MANTENER
  final String? categoria; // ✅ MANTENER
  final double? precioActual; // ✅ MANTENER
  final String vendedorNombre; // ✅ MANTENER

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

// --- MODELOS PARA TRANSACCIONES ---

// Modelo simplificado para las listas de compras/ventas
class TransactionSummary {
  final int id;
  final DateTime fecha;
  final String estado;
  final int cantidad;
  final double precioTotal;
  final bool confirmacionComprador;
  final bool confirmacionVendedor;
  final TransactionProductInfo producto;
  final TransactionUserInfo? comprador; // Nullable en la lista de compras
  final TransactionUserInfo? vendedor; // Nullable en la lista de ventas

  TransactionSummary({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.cantidad,
    required this.precioTotal,
    required this.confirmacionComprador,
    required this.confirmacionVendedor,
    required this.producto,
    this.comprador,
    this.vendedor,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] ?? 0,
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      estado: json['estado'] ?? 'Desconocido',
      cantidad: json['cantidad'] ?? 0,
      precioTotal: (json['precioTotal'] as num?)?.toDouble() ?? 0.0,
      confirmacionComprador: json['confirmacionComprador'] ?? false,
      confirmacionVendedor: json['confirmacionVendedor'] ?? false,
      producto: TransactionProductInfo.fromJson(json['producto'] ?? {}),
      comprador: json['comprador'] != null
          ? TransactionUserInfo.fromJson(json['comprador'])
          : null,
      vendedor: json['vendedor'] != null
          ? TransactionUserInfo.fromJson(json['vendedor'])
          : null,
    );
  }
}

// Info básica del producto en una transacción
class TransactionProductInfo {
  final int id;
  final String nombre;
  final String? imageUrl; // Placeholder

  TransactionProductInfo({required this.id, required this.nombre, this.imageUrl});

  factory TransactionProductInfo.fromJson(Map<String, dynamic> json) {
    return TransactionProductInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Producto Desconocido',
      // imageUrl: json['imageUrl'], // Ajustar si la API envía la imagen
    );
  }
}

// Info básica del usuario (comprador/vendedor) en una transacción
class TransactionUserInfo {
  final int id;
  final String nombreCompleto;
  final String? usuario;

  TransactionUserInfo({required this.id, required this.nombreCompleto, this.usuario});

  factory TransactionUserInfo.fromJson(Map<String, dynamic> json) {
    return TransactionUserInfo(
      id: json['id'] ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? 'Usuario Desconocido',
      usuario: json['usuario'],
    );
  }
}

// Respuesta para las listas de transacciones (con paginación)
class TransactionListResponse {
  final bool ok;
  final List<TransactionSummary> transactions;
  final PaginationInfo pagination;

  TransactionListResponse({
    required this.ok,
    required this.transactions,
    required this.pagination,
  });

  factory TransactionListResponse.fromJsonPurchases(Map<String, dynamic> json) {
    return TransactionListResponse(
      ok: json['ok'] ?? false,
      transactions: (json['purchases'] as List<dynamic>?)
              ?.map((item) => TransactionSummary.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
   factory TransactionListResponse.fromJsonSales(Map<String, dynamic> json) {
    return TransactionListResponse(
      ok: json['ok'] ?? false,
      transactions: (json['sales'] as List<dynamic>?)
              ?.map((item) => TransactionSummary.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
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
