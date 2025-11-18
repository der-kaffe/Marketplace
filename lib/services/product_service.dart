// lib/services/product_service.dart

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
  final AuthService _authService = AuthService();

  /// ✅ Obtiene productos desde el backend real (paginados y filtrables)
  Future<List<Product>> fetchProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    print('🟢 ProductService.fetchProducts: page=[32m$page[0m, limit=[32m$limit[0m, category=[32m$category[0m, search=[32m$search[0m');
    try {
      // Obtener token y setear en api client si existe
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _apiClient.setToken(token);
      } else {
        _apiClient.clearToken();
      }

      final response = await _apiClient.getProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      // Convertir cada ProductFromDB a ProductModel.Product
      final list = response.products.map((p) => p.toProductModel()).toList();
      print('🟢 ProductService.fetchProducts: productos recibidos = [32m${list.length}[0m');
      return list;
    } catch (e) {
      debugPrint('❌ Error cargando productos: $e');
      return [];
    }
  }

  /// ✅ Cambia visibilidad del producto (admin o vendedor)
  Future<void> toggleVisibility({
    required int productId,
    required bool visible,
  }) async {
    try {
      final token = await _auth_service_token_or_throw();
      // ApiClient maneja headers internamente si setToken fue invocado
      _apiClient.setToken(token);

      await _apiClient.updateProductVisibility(productId, visible);
    } catch (e) {
      debugPrint('❌ Error en toggleVisibility (service): $e');
      rethrow;
    }
  }
  
  /// ✅ Crear nuevo producto
  Future<Map<String, dynamic>> createProduct({
    required String nombre,
    required String descripcion,
    required double precioActual,
    required int categoriaId,
    double? precioAnterior,
    int? cantidad,
    String? imageUrl,
    String? informacionTecnica,
    String? estadoProducto,
    String? tiempoUso,
    List<String>? imagenes,
  }) async {
    try {
      final token = await _auth_service_token_or_throw();
      _apiClient.setToken(token);

      final result = await _apiClient.createProduct(
        nombre: nombre,
        descripcion: descripcion,
        precioActual: precioActual,
        categoriaId: categoriaId,
        precioAnterior: precioAnterior,
        cantidad: cantidad,
        imageUrl: imageUrl,
        informacionTecnica: informacionTecnica,
        estadoProducto: estadoProducto,
        tiempoUso: tiempoUso,
        imagenes: imagenes,
      );

      return result;
    } catch (e) {
      debugPrint('❌ Error en createProduct (service): $e');
      rethrow;
    }
  }

  /// 🖼️ Crear producto con múltiples imágenes (nueva función específica)
  Future<Map<String, dynamic>> createProductWithMultipleImages({
    required String nombre,
    required String descripcion,
    required double precioActual,
    required int categoriaId,
    required List<String> imagenes, // Lista de imágenes base64
    double? precioAnterior,
    int? cantidad,
    String? informacionTecnica,
    String? estadoProducto,
    String? tiempoUso,
  }) async {
    return await createProduct(
      nombre: nombre,
      descripcion: descripcion,
      precioActual: precioActual,
      categoriaId: categoriaId,
      precioAnterior: precioAnterior,
      cantidad: cantidad,
      imageUrl: null, // No usar imageUrl individual
      imagenes: imagenes, // Usar lista de imágenes
      informacionTecnica: informacionTecnica,
      estadoProducto: estadoProducto,
      tiempoUso: tiempoUso,
    );
  }

  /// 🗑️ Eliminar producto
  Future<void> deleteProduct(int productId) async {
    try {
      final token = await _auth_service_token_or_throw();
      _apiClient.setToken(token);

      await _apiClient.deleteProduct(productId);
    } catch (e) {
      debugPrint('❌ Error al eliminar producto: $e');
      rethrow;
    }
  }

  /// ✏️ Actualizar producto (ejemplo: precio, descripción, etc.)
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? nombre,
    String? descripcion,
    double? precioActual,
    int? categoriaId,
  }) async {
    try {
      final token = await _auth_service_token_or_throw();
      _apiClient.setToken(token);

      final Map<String, dynamic> data = {};
      if (nombre != null) data['nombre'] = nombre;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (precioActual != null) data['precioActual'] = precioActual;
      if (categoriaId != null) data['categoriaId'] = categoriaId;

      final result = await _apiClient.updateProduct(productId, data);
      return result;
    } catch (e) {
      debugPrint('❌ Error al actualizar producto: $e');
      rethrow;
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final token = await _auth_service_token_or_throw();
      _apiClient.setToken(token);

      final response = await _apiClient.getProductById(int.parse(id));

      // ✅ ProductDetailResponse tiene un campo 'product' (tipo ProductFromDB)
      final productFromDB = response.product;

      // ✅ ProductFromDB sí tiene el método toProductModel()
      final productModel = productFromDB.toProductModel();

      return productModel;
    } catch (e) {
      debugPrint('❌ Error al obtener producto por ID: $e');
      return null;
    }
  }


  /// Helper para obtener token o lanzar excepción
  Future<String> _auth_service_token_or_throw() async {
    final token = await _auth_service_token();
    if (token == null || token.isEmpty) {
      throw Exception('Token no disponible (usuario no autenticado)');
    }
    return token;
  }

  Future<String?> _auth_service_token() async {
    try {
      final token = await _auth_service_getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _auth_service_getToken() => _auth_service_wrapper();

  // wrapper para fácil mocking/testing
  Future<String?> _auth_service_wrapper() => _authService.getToken();

  /// ✅ Obtiene categorías desde el backend (usa ApiClient)
  Future<List<ApiCategory>> fetchCategories() async {
    try {
      final categories = await _apiClient.getCategoriesFromApi();
      return categories;
    } catch (e) {
      debugPrint('❌ Error cargando categorías en ProductService: $e');
      return [];
    }
  }

  /// ✅ Obtiene los productos del usuario actual desde el backend
  Future<List<Product>> fetchMyProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _auth_service_token_or_throw();
      _apiClient.setToken(token);

      final response = await _apiClient.getMyProducts(
        page: page,
        limit: limit,
      );

      // Convertir cada ProductFromDB a ProductModel.Product
      final list = response.products.map((p) => p.toProductModel()).toList();
      return list;
    } catch (e) {
      debugPrint('❌ Error cargando mis productos: $e');
      rethrow;
    }
  }
  /// ✅ Obtener info del vendedor. Intenta endpoint /api/users/:id, si no funciona devuelve fallback
  Future<Map<String, dynamic>> getSellerInfo(String sellerId) async {
    try {
      print('🔍 getSellerInfo llamado con sellerId: "$sellerId"'); // Debug
        if (sellerId.isEmpty) {
        return {
          'name': 'Vendedor desconocido',
          'avatar': null,
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': null,
          'estadisticas': {
            'totalPublicaciones': 0,
            'publicacionesActivas': 0,
            'totalVentas': 0,
          },
        };
      }

      final idInt = int.tryParse(sellerId);      if (idInt == null) {
        return {
          'name': sellerId,
          'avatar': null,
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': null,
          'estadisticas': {
            'totalPublicaciones': 0,
            'publicacionesActivas': 0,
            'totalVentas': 0,
          },
        };
      }

      // Intenta obtener del endpoint
      try {
        final userJson = await _apiClient.getUserById(idInt);
        // print('🔍 Datos del vendedor desde backend: $userJson');
        // print('🔍 fotoPerfilUrl específica: ${userJson['fotoPerfilUrl']}');
        // Normalizar campos posibles - usar nombreCompleto si está disponible
        final name = userJson['nombreCompleto'] ?? 
            ((userJson['nombre'] != null)
                ? '${userJson['nombre']}'
                : (userJson['name'] ?? 'Vendedor'));
        final avatar = userJson['fotoPerfilUrl']; // Usar directamente fotoPerfilUrl del backend
        final campus = userJson['campus'] ?? 'Desconocido';
        // print('✅ Procesando avatar: $avatar');
        // print('✅ Nombre procesado: $name');
        final reputacion = (userJson['reputacion'] != null)
            ? double.tryParse(userJson['reputacion'].toString()) ?? 0.0
            : 0.0;          // ✅ NUEVO: Extraer estadísticas del vendedor
        final estadisticas = userJson['estadisticas'] ?? {};
        
        // print('🔍 Estadísticas extraídas del backend: $estadisticas');
        
        return {
          'name': name,
          'avatar': avatar,
          'campus': campus,
          'reputacion': reputacion,
          'id': idInt,
          'correo': userJson['correo'],
          'miembroDesde': userJson['fechaRegistro'],
          // ✅ DEVOLVER estadísticas como objeto completo (igual que el backend)
          'estadisticas': estadisticas,
        };      } catch (e) {
        debugPrint('⚠️ getUserById falló, usando fallback: $e');
        return {
          'name': 'Vendedor #$sellerId',
          'avatar': null,
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': idInt,
          'estadisticas': {
            'totalPublicaciones': 0,
            'publicacionesActivas': 0,
            'totalVentas': 0,
          },
        };
      }    } catch (e) {
      debugPrint('❌ Error en getSellerInfo: $e');
      return {
        'name': 'Vendedor desconocido',        'avatar': null,
        'campus': 'Desconocido',
        'reputacion': 0.0,
        'id': null,
        'estadisticas': {
          'totalPublicaciones': 0,
          'publicacionesActivas': 0,
          'totalVentas': 0,
        },
      };
    }
  }

  /// 🔧 Helper para íconos de categorías (igual que antes)
  static IconData getIconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'vehículos':
      case 'vehiculos':
        return Icons.directions_car;
      case 'inmuebles':
        return Icons.home;
      case 'electrónica':
      case 'electronica':
        return Icons.devices;
      case 'ropa':
        return Icons.checkroom;
      case 'deportes':
        return Icons.sports_soccer;
      case 'hogar':
        return Icons.chair;
      default:
        return Icons.category;
    }
  }
}
