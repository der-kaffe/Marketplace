// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/api_client.dart';
import '../services/websocket_service.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_modal.dart';

// Instancia global para manejar Google Sign-In
final GoogleSignIn _googleSignIn = GoogleSignIn();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  // Datos del usuario (obtenidos del backend)
  String _userName = 'Usuario';
  String _userEmail = 'usuario@ejemplo.com';
  String? _userPhotoUrl;
  // Campos editables
  String _usuario = '';
  String _campus = 'Campus Temuco';
  String? _telefono;
  String? _direccion;

  final ProductService _productService = ProductService();
  List<Product> _myProducts = [];
  bool _isLoadingMyProducts = true;

  int _favoritesCount = 0;
  final Set<String> _favoriteProductIds = {};
  int _reviewsCount = 0; // Placeholder

  // --- ✅ NUEVO: Estado para Transacciones ---
  final ApiClient _apiClient = ApiClient(baseUrl: getDefaultBaseUrl());
  final AuthService _authService = AuthService(); 
  List<TransactionSummary> _myPurchases = [];
  List<TransactionSummary> _mySales = [];
  bool _isLoadingPurchases = true;
  bool _isLoadingSales = true;
  bool _isUploadingPhoto = false; // Para mostrar indicador de carga
  bool _keepSessionActive = false; // Para mantener sesión iniciada

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUserData(),
        _loadMyProducts(),
        _loadFavoritesCount(),
        _loadMyPurchases(),
        _loadMySales(),
        _loadKeepSessionState(), // ✅ NUEVO: Cargar estado de sesión
      ]);
    } catch (e) {
      print('Error inicializando perfil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 Cargando datos del perfil desde backend...');

      // ✅ NUEVO: Primero intentar obtener datos frescos del backend
      try {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          _authService.apiClient.setToken(token);
          final profileResponse = await _authService.apiClient.getUserProfile();
          
          if (profileResponse['success'] == true) {
            final userData = profileResponse['data'];
            final updatedUser = User.fromJson(userData);
            await _authService.saveUserData(updatedUser);
            print('🔄 Datos del perfil actualizados desde el backend');
          }
        }
      } catch (e) {
        print('⚠️ No se pudo obtener datos frescos del backend: $e');
      }

      // Obtener datos del usuario actual desde AuthService
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('👤 Usuario actual del AuthService: ${currentUser.name}');        setState(() {
          _userName = currentUser.name;
          _userEmail = currentUser.email;
          // ✅ CORREGIR: Manejar valores nullable con ?? ''
          _usuario = currentUser.usuario ?? '';
          _campus = currentUser.campus ?? 'Campus Temuco';
          _telefono = currentUser.telefono;
          _direccion = currentUser.direccion;
          // ✅ USAR foto de perfil del usuario o como fallback la de Google
          if (currentUser.fotoPerfilUrl != null) {
            _userPhotoUrl = currentUser.fotoPerfilUrl!.startsWith('http') 
                ? currentUser.fotoPerfilUrl 
                : '${_apiClient.baseUrl}${currentUser.fotoPerfilUrl}';
          }
        });
        print('🧠 Rol del usuario: ${currentUser.role}');
        print('🔑 rolId: ${currentUser.rolId}');
        print('👑 ¿Es admin?: ${currentUser.isAdmin}');
        print('✅ Datos cargados exitosamente');
      } else {
        print('⚠️ No hay usuario autenticado');
        // Intentar obtener desde datos de Google como fallback
        final googleData = await _authService.getGoogleUserData();
        if (googleData != null) {
          setState(() {
            _userName = googleData['name'] ?? 'Usuario';
            _userEmail = googleData['email'] ?? 'usuario@ejemplo.com';
            _userPhotoUrl = googleData['photoUrl'];
          });
        }
      }
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      setState(() {
        _userName = 'Usuario';
        _userEmail = 'usuario@ejemplo.com';
        _userPhotoUrl = null;
      });
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
      print('🏁 Carga de perfil completada');
    }
  }

  // --- NUEVO: Método para cargar los productos del usuario ---
  Future<void> _loadMyProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingMyProducts = true);

    try {
      final products = await _productService.fetchMyProducts();
      if (mounted) {
        setState(() {
          _myProducts = products;
          _isLoadingMyProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mis productos: $e')),
        );
      }
    }
  }

  Future<void> _loadFavoritesCount() async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _authService.apiClient.setToken(token);
      }
      final resp = await _authService.apiClient.getProductFavorites(page: 1, limit: 100);
      if (mounted) {
        setState(() {
          _favoritesCount = resp.favorites.length;
          _favoriteProductIds.clear();
          for (var fav in resp.favorites) {
            _favoriteProductIds.add(fav.productoId.toString());
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _favoritesCount = 0);
      }
    }
  }

  // Reemplaza el método de refresco para usar la inicialización paralela  // --- ✅ NUEVO: Métodos para cargar Compras y Ventas ---
  Future<void> _loadMyPurchases() async {
    if (!mounted) return;
    setState(() => _isLoadingPurchases = true);
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token); // Asegurar token en ApiClient

      final response = await _apiClient.getMyPurchases();
      if (mounted) {
        setState(() {
          _myPurchases = response.transactions;
          _isLoadingPurchases = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando mis compras: $e');
      if (mounted) {
        setState(() => _isLoadingPurchases = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar compras: ${e is ApiException ? e.message : e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMySales() async {
    if (!mounted) return;
    setState(() => _isLoadingSales = true);
    try {
       final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token); // Asegurar token en ApiClient

      final response = await _apiClient.getMySales();
       if (mounted) {
        setState(() {
          _mySales = response.transactions;
          _isLoadingSales = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando mis ventas: $e');
      if (mounted) {
        setState(() => _isLoadingSales = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al cargar ventas: ${e is ApiException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- ✅ NUEVO: Métodos para Confirmar (ventas vendidas)---
  Future<void> _confirmReceipt(int transactionId) async {
    // Mostrar diálogo de confirmación (opcional pero recomendado)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Recibo'),
        content: const Text('¿Confirmas que has recibido este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return; // Si cancela, no hacer nada

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Confirmando recibo...'), duration: Duration(seconds: 1)),
    );

    try {
      final token = await _authService.getToken();
       if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token);

      await _apiClient.confirmReceipt(transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Recibo confirmado!'), backgroundColor: Colors.green),
        );
        // Recargar la lista de compras para ver el cambio de estado
        await _loadMyPurchases();
      }
    } catch (e) {
       print('❌ Error confirmando recibo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e is ApiException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  /// ✅ NUEVO: Confirmar/aceptar venta (confirmación inicial del vendedor)
  Future<void> _confirmSale(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar Venta'),
        content: const Text('¿Deseas aceptar esta venta? El comprador será notificado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceptar Venta'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aceptando venta...'), duration: Duration(seconds: 1)),
    );

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token);

      await _apiClient.confirmSale(transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Venta aceptada! El comprador ha sido notificado.'), backgroundColor: Colors.green),
        );
        await _loadMySales();
      }
    } catch (e) {
      print('❌ Error confirmando venta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e is ApiException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// ✅ NUEVO: Rechazar/cancelar venta
  Future<void> _rejectSale(int transactionId) async {
    final TextEditingController motivoController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de que deseas rechazar esta venta? El stock será devuelto.'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rechazando venta...'), duration: Duration(seconds: 1)),
    );

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token);

      final motivo = motivoController.text.trim();
      await _apiClient.rejectSale(transactionId, motivo: motivo.isNotEmpty ? motivo : null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Venta rechazada. El stock ha sido devuelto.'), backgroundColor: Colors.orange),
        );
        await _loadMySales();
      }
    } catch (e) {
      print('❌ Error rechazando venta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e is ApiException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelivery(int transactionId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: const Text('¿Confirmas que has entregado este producto al comprador? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Confirmando entrega...'), duration: Duration(seconds: 1)),
    );

    try {
       final token = await _authService.getToken();
       if (token == null) throw Exception("No autenticado");
      _apiClient.setToken(token);

      await _apiClient.confirmDelivery(transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Entrega confirmada!'), backgroundColor: Colors.green),
        );
        // Recargar la lista de ventas
        await _loadMySales();
      }
    } catch (e) {
      print('❌ Error confirmando entrega: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e is ApiException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ NUEVO: Cargar estado de "Mantener sesión iniciada"
  Future<void> _loadKeepSessionState() async {
    try {
      final keepSession = await _authService.getKeepSessionActive() ?? false;
      if (mounted) {
        setState(() {
          _keepSessionActive = keepSession;
        });
      }
    } catch (e) {
      print('Error cargando estado de sesión: $e');
    }
  }

  // ✅ NUEVO: Alternar estado de "Mantener sesión iniciada"
  Future<void> _toggleKeepSession(bool value) async {
    try {
      await _authService.setKeepSessionActive(value);
      if (mounted) {
        setState(() {
          _keepSessionActive = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                ? '✅ Sesión se mantendrá iniciada' 
                : '🔒 Sesión se cerrará automáticamente'
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error actualizando estado de sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar configuración de sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para alternar favoritos
  Future<void> _toggleFavorite(Product product) async {
    try {
      final productId = int.parse(product.id);
      final isFavorite = _favoriteProductIds.contains(product.id);

      if (isFavorite) {
        await _authService.apiClient.removeProductFavorite(productoId: productId);
        setState(() {
          _favoriteProductIds.remove(product.id);
          _favoritesCount--; // Actualiza el contador
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eliminado de favoritos')),
          );
        }
      } else {
        await _authService.apiClient.addProductFavorite(productoId: productId);
        setState(() {
          _favoriteProductIds.add(product.id);
          _favoritesCount++; // Actualiza el contador
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregado a favoritos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Método para alternar visibilidad del producto
  Future<void> _toggleProductVisibility(Product product) async {
    try {
      final productId = int.tryParse(product.id);
      if (productId == null) {
        throw Exception('ID de producto inválido');
      }

      // 1. Tarea Futura: Lógica de "Vendido"
      // Aquí es donde implementarás la lógica de "ocultar si está vendido"
      // if (product.estadoProducto == 'vendido') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('No se puede cambiar la visibilidad de un producto vendido.')),
      //   );
      //   return; 
      // }

      final newVisibility = !product.isAvailable;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const SizedBox(width: 16),
              Text(newVisibility ? 'Haciendo público...' : 'Ocultando...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // 2. Llamar al backend
      await _productService.toggleVisibility(
        productId: productId,
        visible: newVisibility,
      );

      // 3. Actualizar UI local (adaptado para _myProducts)
      setState(() {
        final productIndex = _myProducts.indexWhere((p) => p.id == product.id);
        if (productIndex != -1) {
          _myProducts[productIndex] = product.copyWith(isAvailable: newVisibility);
        }
      });

      // 4. Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newVisibility
                  ? '✅ Producto visible para todos'
                  : '🔒 Producto oculto',
            ),
            backgroundColor: newVisibility ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 5. Manejo de errores
      print('❌ Error cambiando visibilidad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para cambiar foto de perfil
  Future<void> _changeProfilePhoto() async {
    try {
      // Mostrar opciones de selección
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Elegir de galería'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancelar'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      setState(() => _isUploadingPhoto = true);

      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Subiendo foto de perfil...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }      // Subir imagen al servidor
      print('📸 Subiendo foto de perfil desde: ${image.path}');
      final response = await _apiClient.uploadProfilePhoto(image.path);
      print('📸 Respuesta del servidor: $response');

      if (response['ok'] == true) {
        // Actualizar la URL de la foto localmente
        final newPhotoUrl = response['photoUrl'];
        final fullUrl = '${_apiClient.baseUrl}$newPhotoUrl';
        
        setState(() {
          _userPhotoUrl = fullUrl;
          _isUploadingPhoto = false;
        });

        // ✅ NUEVO: Actualizar también el usuario en AuthService para persistir la foto
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          final updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            name: currentUser.name,
            rolId: currentUser.rolId,
            role: currentUser.role,
            usuario: currentUser.usuario,
            campus: currentUser.campus,
            telefono: currentUser.telefono,
            direccion: currentUser.direccion,
            fotoPerfilUrl: newPhotoUrl, // ✅ Actualizar con la nueva URL relativa
          );
          await _authService.saveUserData(updatedUser);
          print('📸 Foto de perfil actualizada en AuthService: $newPhotoUrl');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Foto de perfil actualizada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      print('❌ Error cambiando foto de perfil: $e');
      setState(() => _isUploadingPhoto = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            body: Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 50.0,
              ),
            ),
          )
        : Container(
            color: AppColors.fondoClaro,
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // Encabezado del perfil
                _buildProfileHeader(),

                const SizedBox(height: 20),
                // Información personal
                _buildInfoSection(
                  title: 'Información Personal',                  items: [
                    _buildInfoItem(Icons.person, 'Nombre completo', _userName),
                    _buildInfoItem(Icons.email, 'Email', _userEmail),                    _buildSwitchItem(
                      icon: Icons.lock_clock,
                      title: 'Mantener sesión iniciada',
                      subtitle: 'La sesión no se cerrará automáticamente',
                      value: _keepSessionActive,
                      onChanged: _toggleKeepSession,
                    ),
                    _buildInfoItem(Icons.account_circle, 'Usuario', _usuario),
                    _buildEditableInfoItem(Icons.school, 'Campus', _campus,
                        () => _editField('campus')),
                    _buildEditableInfoItem(
                        Icons.phone,
                        'Teléfono',
                        _telefono ?? 'No especificado',
                        () => _editField('teléfono')),
                    _buildEditableInfoItem(
                        Icons.location_on,
                        'Dirección',
                        _direccion ?? 'No especificada',
                        () => _editField('dirección')),
                  ],
                ),
                
                const SizedBox(height: 16),
                // --- NUEVO: Sección "Mis Productos" ---
                _buildMyProductsSection(),
                const SizedBox(height: 16),

                // secciones de Compras y Ventas
                _buildPurchasesSection(),
                const SizedBox(height: 16),
                _buildSalesSection(),
                const SizedBox(height: 16),

                const SizedBox(height: 16), // Opciones de cuenta
                _buildInfoSection(
                  title: 'Mi Cuenta',
                  items: [                    _buildActionItem(
                      icon: Icons.favorite,
                      title: 'Mis Favoritos',
                      color: AppColors.error,
                      onTap: () => context.push('/home/favorites'),
                    ),
                    _buildActionItem(
                      icon: Icons.notifications,
                      title: 'Notificaciones',
                      color: AppColors.amarilloPrimario,
                      onTap: () => context.push('/home/notifications'),
                    ),
                    _buildActionItem(
                      icon: Icons.history,
                      title: 'Historial de Transacciones',
                      color: Colors.indigo,
                      onTap: () => context.push('/transactions'),
                    ),
                    if (AuthService().isAdmin)
                      _buildActionItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Panel de Administrador',
                        color: Colors.deepPurple,
                        onTap: () => context.push('/admin'),
                      ),
                    _buildActionItem(
                      icon: Icons.logout,
                      title: 'Cerrar Sesión',
                      color: AppColors.error,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Versión de la aplicación
                const Center(
                  child: Text(
                    'MicroMarket v1.0.0',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
  }

  // Encabezado del perfil con foto y nombre
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 30, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.azulPrimario,
            AppColors.azulOscuro,
          ],
        ),
      ),
      child: Column(
        children: [          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.blanco, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).toInt()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isUploadingPhoto
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrimario),
                        )
                      : _userPhotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                _userPhotoUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.azulPrimario,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.azulPrimario,
                            ),
                ),
                // Icono de cámara para indicar que es clickeable
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.amarilloPrimario,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blanco, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.textoOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.blanco,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amarilloPrimario,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Usuario',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textoOscuro,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatistic(_myProducts.length.toString(), 'Publicaciones'),
              _verticalDivider(),
              _buildStatistic(_favoritesCount.toString(), 'Favoritos'),
              _verticalDivider(),
              _buildStatistic(_reviewsCount.toString(), 'Reseñas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blanco,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.blanco.withAlpha((0.8 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.blanco.withAlpha((0.3 * 255).toInt()),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.azulPrimario,
              ),
            ),
          ),
          const Divider(),
          ...items,
        ],
      ),
    );
  }
  
  Widget _buildMyProductsSection() {
    return _buildInfoSection(
      title: 'Mis Publicaciones',
      items: [
        if (_isLoadingMyProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_myProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  const Text('No has publicado ningún producto.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () => context.push('/new_post'),
                      child: const Text('Publicar mi primer producto'))
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            height: 260, // Altura ajustada para la tarjeta
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _myProducts.length,
              itemBuilder: (context, index) {
                final product = _myProducts[index];
                
                // ✅ ESTADO DE FAVORITO EN TIEMPO REAL
                final isFavorite = _favoriteProductIds.contains(product.id);

                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),                  child: ProductCard(
                    title: product.title,
                    description: product.description,
                    price: product.price,
                    imageUrl: product.imageUrl,
                    imagenes: product.imagenes, // 🖼️ Múltiples imágenes
                    
                    // ✅ PASA EL VALOR CALCULADO
                    isFavorite: isFavorite, 
                    
                    isAvailable: product.isAvailable,
                    estadoProducto: product.estadoProducto,
                    tiempoUso: product.tiempoUso,

                    // 👤 Información del vendedor
                    sellerId: product.sellerId,
                    sellerName: product.sellerName,
                    sellerAvatar: product.sellerAvatar,

                    // ✅ CONECTA LOS MÉTODOS REALES
                    onToggleFavorite: () => _toggleFavorite(product),
                    onToggleVisibility: () => _toggleProductVisibility(product),

                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ProductDetailModal(product: product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.azulPrimario),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textoSecundario)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textoOscuro),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget para item con switch
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.azulPrimario),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textoOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.azulPrimario,
            activeTrackColor: AppColors.azulPrimario.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // --- ✅ NUEVO: Widgets para construir las secciones de Compras y Ventas ---
  Widget _buildPurchasesSection() {
    return _buildInfoSection(
      title: 'Mis Compras',
      items: [
        if (_isLoadingPurchases)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_myPurchases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No has realizado ninguna compra aún.')),
          )
        else
          // Usamos ListView.separated para añadir divisores
          ListView.separated(
            shrinkWrap: true, // Importante dentro de otro ListView
            physics: const NeverScrollableScrollPhysics(), // Evitar scroll anidado
            itemCount: _myPurchases.length,
            itemBuilder: (context, index) {
              final purchase = _myPurchases[index];
              return _buildTransactionTile(purchase, isPurchase: true);
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
      ],
    );
  }

  Widget _buildSalesSection() {
     return _buildInfoSection(
      title: 'Mis Ventas',
      items: [
        if (_isLoadingSales)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_mySales.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No has realizado ninguna venta aún.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mySales.length,
            itemBuilder: (context, index) {
              final sale = _mySales[index];
              return _buildTransactionTile(sale, isPurchase: false);
            },
             separatorBuilder: (context, index) => const Divider(height: 1),
          ),
      ],
    );
  }
  // Widget reutilizable para mostrar una compra o venta
  Widget _buildTransactionTile(TransactionSummary transaction, {required bool isPurchase}) {
    final user = isPurchase ? transaction.vendedor : transaction.comprador;
    final canConfirm = transaction.estado == 'Pendiente';
    final alreadyConfirmed = isPurchase ? transaction.confirmacionComprador : transaction.confirmacionVendedor;
    
    // Para ventas: si está pendiente Y el vendedor NO ha confirmado, mostrar botones de aceptar/rechazar
    final isVentaPendiente = !isPurchase && canConfirm && !transaction.confirmacionVendedor;
    
    // Para ventas confirmadas o compras: mostrar botón de entregado/recibido
    final showConfirmButton = canConfirm && alreadyConfirmed && !isVentaPendiente;

    return ListTile(
      title: Text(transaction.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${DateFormat('dd/MM/yyyy HH:mm').format(transaction.fecha)} - ${_formatCLP(transaction.precioTotal)}'),
          if (user != null) Text(isPurchase ? 'Vendedor: ${user.nombreCompleto}' : 'Comprador: ${user.nombreCompleto}'),
          Row(
            children: [
              Text('Estado: ${transaction.estado}'),
              const SizedBox(width: 8),
              if (transaction.confirmacionVendedor) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
              if (transaction.confirmacionComprador) const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          // ✅ Mostrar botones de aceptar/rechazar para ventas pendientes
          if (isVentaPendiente) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmSale(transaction.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Aceptar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectSale(transaction.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: showConfirmButton
          ? ElevatedButton(
              onPressed: () {
                if (isPurchase) {
                  _confirmReceipt(transaction.id);
                } else {
                  _confirmDelivery(transaction.id);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                backgroundColor: isPurchase ? Colors.green : Colors.blue,
              ),
              child: Text(isPurchase ? 'Recibido' : 'Entregado', style: const TextStyle(fontSize: 12)),
            )
          : null,
      isThreeLine: true,
    );
  }

  String _formatCLP(num value) {
    final format =
        NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    // Elimina el espacio y el símbolo CLP si lo agrega
    return format
        .format(value)
        .replaceAll('CLP', '')
        .replaceAll(' ', '')
        .trim();
  }


  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textoOscuro)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.grisPrimario),
          ],
        ),
      ),
    );
  }



  // 🔹 Logout con confirmación, Google Sign-In y go_router
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar la sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  // 🔹 Desconectar el socket antes de cerrar sesión
                  final wsService = WebSocketService();
                  wsService.disconnect();

                  // 🔹 Cerrar sesión en Google
                  await _googleSignIn.signOut();

                  // 🔹 Borrar token local (clave: session_token)
                  final authService = AuthService();
                  await authService.deleteToken();
                } catch (e) {
                  debugPrint("Error al cerrar sesión: $e");
                }

                // 🔹 Ahora sí, ir a login
                context.go('/login');
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Widget para campos editables
  Widget _buildEditableInfoItem(
      IconData icon, String label, String value, VoidCallback onEdit) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.azulPrimario.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.azulPrimario),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textoSecundario)),                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textoOscuro),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: AppColors.grisPrimario, size: 20),
          ],
        ),
      ),
    );  }

  // Método auxiliar para obtener el valor actual de un campo
  String _getCurrentValue(String fieldType) {
    switch (fieldType) {
      case 'campus':
        return _campus;
      case 'teléfono':
        return _telefono ?? '';
      case 'dirección':
        return _direccion ?? '';
      default:
        return '';
    }
  }

  // Método para editar campos
  void _editField(String fieldType) {
    String currentValue = _getCurrentValue(fieldType);
    TextEditingController controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar $fieldType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fieldType == 'campus') ...[
                const Text(
                  'Selecciona tu campus:',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _getCampusDropdownValue(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Campus',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Campus Temuco',
                        child: Text('Campus Temuco - Sede Principal')),
                    DropdownMenuItem(
                        value: 'Campus Norte', child: Text('Campus Norte UCT')),
                    DropdownMenuItem(
                        value: 'Campus San Francisco',
                        child: Text('Campus San Francisco')),
                    DropdownMenuItem(
                        value: 'Campus Menchaca Lira',
                        child: Text('Campus Menchaca Lira')),
                    DropdownMenuItem(
                        value: 'Campus Rivas del Canto',
                        child: Text('Campus Rivas del Canto')),
                  ],
                  onChanged: (value) {
                    controller.text = value ?? 'Campus Temuco';
                  },
                ),
                const SizedBox(height: 12),
              ],              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: fieldType == 'teléfono'
                      ? 'Número de teléfono'
                      : fieldType == 'campus'
                          ? 'Campus'
                          : 'Dirección',                  hintText: fieldType == 'teléfono'
                      ? '+56 9 1234 5678'
                      : fieldType == 'campus'
                          ? 'Campus Temuco'
                          : 'Ej: Av. Alemania 0211, Temuco',
                ),
                keyboardType: fieldType == 'teléfono'
                    ? TextInputType.phone
                    : TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Cerrar el diálogo INMEDIATAMENTE
                Navigator.of(context).pop();

                // Luego ejecutar la actualización
                await _saveField(fieldType, controller.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  } // Método para obtener el valor correcto del dropdown de campus

  String _getCampusDropdownValue() {
    final campusOptions = [
      'Campus Temuco',
      'Campus Norte',
      'Campus San Francisco',
      'Campus Menchaca Lira',
      'Campus Rivas del Canto'
    ];

    if (campusOptions.contains(_campus)) {
      return _campus;
    }
    return 'Campus Temuco';
  } // Método para guardar un campo editado

  Future<void> _saveField(String fieldType, String newValue) async {
    try {
      print('🔄 Iniciando actualización de $fieldType: $newValue');

      // Verificar autenticación
      final authService = AuthService();
      final token = await authService.getToken();
      final currentUser = authService.currentUser;

      print('🔑 Token disponible: ${token != null ? 'SÍ' : 'NO'}');
      print('👤 Usuario actual: ${currentUser?.name ?? 'NINGUNO'}');

      if (token == null) {
        throw Exception(
            'No hay token de autenticación. Por favor, inicia sesión nuevamente.');
      }

      // Llamar al backend para actualizar
      final apiClient = authService.apiClient;      // Crear el objeto de actualización con solo el campo que cambió
      Map<String, String?> updateParams = {};
      switch (fieldType) {
        case 'campus':
          updateParams['campus'] = newValue;
          break;
        case 'teléfono':
          updateParams['telefono'] = newValue.isEmpty ? null : newValue;
          break;
        case 'dirección':
          updateParams['direccion'] = newValue.isEmpty ? null : newValue;
          break;
      }      final response = await apiClient.updateProfile(
        // ✅ REMOVIDO: usuario: updateParams['usuario'],
        campus: updateParams['campus'],
        telefono: updateParams['telefono'],
        direccion: updateParams['direccion'],
      );

      print('✅ Respuesta del servidor: $response');      // Solo actualizar localmente si la llamada al backend fue exitosa
      if (mounted) {
        setState(() {
          switch (fieldType) {
            case 'campus':
              _campus = newValue;
              break;
            case 'teléfono':
              _telefono = newValue.isEmpty ? null : newValue;
              break;
            case 'dirección':
              _direccion = newValue.isEmpty ? null : newValue;
              break;
          }
        });

        print('💾 Campo $fieldType actualizado en backend');

        // Mensaje específico con el valor actualizado
        String mensaje = _getUpdateMessage(fieldType, newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.exito,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error actualizando $fieldType: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error actualizando $fieldType: ${_getErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }    }
  }

  // Función para generar mensajes específicos de actualización
  String _getUpdateMessage(String fieldType, String newValue) {
    switch (fieldType) {
      case 'campus':
        return 'Campus actualizado a: $newValue';
      case 'teléfono':
        return newValue.isEmpty
            ? 'Teléfono eliminado correctamente'
            : 'Teléfono actualizado a: $newValue';
      case 'dirección':
        return newValue.isEmpty
            ? 'Dirección eliminada correctamente'
            : 'Dirección actualizada a: $newValue';
      default:
        return '$fieldType actualizado correctamente';
    }
  }
  // Función para generar mensajes de error más claros
  String _getErrorMessage(String error) {
    if (error.contains('TOKEN_INVALID') ||
        error.contains('TOKEN_REQUIRED')) {
      return 'Sesión expirada. Por favor, inicia sesión nuevamente';
    } else if (error.contains('Connection refused') ||
        error.contains('NetworkException')) {
      return 'Sin conexión al servidor';
    } else if (error.contains('VALIDATION_ERROR')) {
      return 'Datos inválidos';
    } else {
      return 'Error inesperado';
    }
  }
}