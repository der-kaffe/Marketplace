// lib/services/product_service.dart

import 'dart:convert';
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
      );

      return result;
    } catch (e) {
      debugPrint('❌ Error en createProduct (service): $e');
      rethrow;
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
      if (sellerId.isEmpty) {
        return {
          'name': 'Vendedor desconocido',
          'avatar': 'https://via.placeholder.com/150',
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': null,
        };
      }

      final idInt = int.tryParse(sellerId);
      if (idInt == null) {
        // no es numérico -> devolver fallback
        return {
          'name': sellerId,
          'avatar': 'https://via.placeholder.com/150',
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': null,
        };
      }

      // Intenta obtener del endpoint
      try {
        final userJson = await _apiClient.getUserById(idInt);
        // Normalizar campos posibles
        final name = (userJson['nombre'] != null)
            ? '${userJson['nombre']}${userJson['apellido'] != null ? ' ${userJson['apellido']}' : ''}'
            : (userJson['name'] ?? 'Vendedor');
        final avatar = userJson['avatar'] ??
            userJson['imagen'] ??
            'https://via.placeholder.com/150';
        final campus = userJson['campus'] ?? 'Desconocido';
        final reputacion = (userJson['reputacion'] != null)
            ? double.tryParse(userJson['reputacion'].toString()) ?? 0.0
            : 0.0;
        return {
          'name': name,
          'avatar': avatar,
          'campus': campus,
          'reputacion': reputacion,
          'id': idInt,
        };
      } catch (e) {
        // Si falla la request (endpoint puede no existir), devolvemos fallback razonable
        debugPrint('⚠️ getUserById falló, usando fallback: $e');
        return {
          'name': 'Vendedor #$sellerId',
          'avatar': 'https://via.placeholder.com/150',
          'campus': 'Desconocido',
          'reputacion': 0.0,
          'id': idInt,
        };
      }
    } catch (e) {
      debugPrint('❌ Error en getSellerInfo: $e');
      return {
        'name': 'Vendedor desconocido',
        'avatar': 'https://via.placeholder.com/150',
        'campus': 'Desconocido',
        'reputacion': 0.0,
        'id': null,
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
