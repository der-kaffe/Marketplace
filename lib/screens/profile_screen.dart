// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart'; // Importar servicio de productos
import '../models/product_model.dart'; // Importar modelo de producto
import '../widgets/product_card.dart'; // Reutilizar la tarjeta de producto
import '../widgets/product_detail_modal.dart'; // Reutilizar el modal de detalle

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
  String _apellido = '';
  String _usuario = '';
  String _campus = 'Campus Temuco';
  String? _telefono;
  String? _direccion;

  // --- NUEVO: Estado para los productos del usuario ---
  final ProductService _productService = ProductService();
  List<Product> _myProducts = [];
  bool _isLoadingMyProducts = true;
  // --- FIN NUEVO ---

  int _favoritesCount = 0;
  int _reviewsCount = 0; // Placeholder, actualizar si tienes endpoint

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMyProducts(); // Cargar los productos del usuario
    _loadFavoritesCount();
    // Si tienes endpoint de reseñas, llama aquí a _loadReviewsCount();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 Cargando datos del perfil desde backend...');
      final authService = AuthService();

      // Obtener datos del usuario actual desde AuthService
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        print('👤 Usuario actual del AuthService: ${currentUser.name}');
        setState(() {
          _userName = currentUser.name;
          _userEmail = currentUser.email;
          // ✅ CORREGIR: Manejar valores nullable con ?? ''
          _apellido = currentUser.apellido ?? '';
          _usuario = currentUser.usuario ?? '';
          _campus = currentUser.campus ?? 'Campus Temuco';
          _telefono = currentUser.telefono;
          _direccion = currentUser.direccion;
        });
        print('🧠 Rol del usuario: ${currentUser.role}');
        print('🔑 rolId: ${currentUser.rolId}');
        print('👑 ¿Es admin?: ${currentUser.isAdmin}');
        print('✅ Datos cargados exitosamente');
      } else {
        print('⚠️ No hay usuario autenticado');
        // Intentar obtener desde datos de Google como fallback
        final googleData = await authService.getGoogleUserData();
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
  // --- FIN NUEVO ---

  Future<void> _loadFavoritesCount() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token != null && token.isNotEmpty) {
        authService.apiClient.setToken(token);
      }
      final resp = await authService.apiClient.getProductFavorites(page: 1, limit: 100);
      if (mounted) {
        setState(() {
          _favoritesCount = resp.favorites.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _favoritesCount = 0);
      }
    }
  }

  // Método para refrescar los datos del usuario (simplificado)
  Future<void> _refreshUserData() async {
    print('🔄 Refrescando datos del perfil...');
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
    await _loadMyProducts(); // Refrescar también los productos
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
                  title: 'Información Personal',
                  items: [
                    _buildInfoItem(Icons.person, 'Nombre completo', _userName),
                    _buildInfoItem(Icons.email, 'Email', _userEmail),
                    _buildActionItem(
                      icon: Icons.refresh,
                      title: 'Actualizar datos de perfil',
                      color: AppColors.azulPrimario,
                      onTap: _refreshUserData,
                    ),
                    _buildEditableInfoItem(Icons.person_outline, 'Apellido',
                        _apellido, () => _editField('apellido')),
                    _buildEditableInfoItem(Icons.account_circle, 'Usuario',
                        _usuario, () => _editField('usuario')),
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
                // --- FIN NUEVO ---

                const SizedBox(height: 16),

                const SizedBox(height: 16), // Opciones de cuenta
                _buildInfoSection(
                  title: 'Mi Cuenta',
                  items: [
                    _buildActionItem(
                      icon: Icons.favorite,
                      title: 'Mis Favoritos',
                      color: AppColors.error,
                      onTap: () => _navigateToSection(context, 2),
                    ),
                    _buildActionItem(
                      icon: Icons.notifications,
                      title: 'Notificaciones',
                      color: AppColors.amarilloPrimario,
                      onTap: () =>
                          _showFeatureMessage(context, 'Notificaciones'),
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
            child: _userPhotoUrl != null
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
  
  // --- NUEVO: Widget para construir la sección de "Mis Productos" ---
  Widget _buildMyProductsSection() {
    return _buildInfoSection(
      title: 'Mis Productos',
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
                    child: const Text('Publicar mi primer producto')
                  )
                ],
              )
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
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    title: product.title,
                    description: product.description,
                    price: product.price,
                    imageUrl: product.imageUrl,
                    isFavorite: product.isFavorite,
                    isAvailable: product.isAvailable,
                    onToggleFavorite: () {
                       _showFeatureMessage(context, 'Manejar favoritos desde el perfil');
                    },
                    onToggleVisibility: () {
                      // Lógica para cambiar visibilidad (opcional, requiere más estado)
                       _showFeatureMessage(context, 'Manejar visibilidad desde el perfil');
                    },
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
  // --- FIN NUEVO ---

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
          Column(
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
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildOrderItem({
    required String orderNumber,
    required String date,
    required String status,
    required double amount,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.shopping_bag, color: AppColors.azulPrimario),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(orderNumber,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoOscuro)),
                    Text(_formatCLP(amount),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textoSecundario)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _showFeatureMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.azulPrimario,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToSection(BuildContext context, int index) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    _showFeatureMessage(context, 'Navegando a la sección $index');
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
                          fontSize: 14, color: AppColors.textoSecundario)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textoOscuro),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: AppColors.grisPrimario, size: 20),
          ],
        ),
      ),
    );
  } // Método auxiliar para obtener el valor actual de un campo

  String _getCurrentValue(String fieldType) {
    switch (fieldType) {
      case 'apellido':
        return _apellido;
      case 'usuario':
        return _usuario;
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
              ],
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: fieldType == 'teléfono'
                      ? 'Número de teléfono'
                      : fieldType == 'apellido'
                          ? 'Apellido'
                          : fieldType == 'usuario'
                              ? 'Nombre de usuario'
                              : fieldType == 'campus'
                                  ? 'Campus'
                                  : 'Dirección',
                  hintText: fieldType == 'teléfono'
                      ? '+56 9 1234 5678'
                      : fieldType == 'apellido'
                          ? 'Ej: García'
                          : fieldType == 'usuario'
                              ? 'Ej: juan_garcia'
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
      final apiClient = authService.apiClient;

      // Crear el objeto de actualización con solo el campo que cambió
      Map<String, String?> updateParams = {};
      switch (fieldType) {
        case 'apellido':
          updateParams['apellido'] = newValue;
          break;
        case 'usuario':
          updateParams['usuario'] = newValue;
          break;
        case 'campus':
          updateParams['campus'] = newValue;
          break;
        case 'teléfono':
          updateParams['telefono'] = newValue.isEmpty ? null : newValue;
          break;
        case 'dirección':
          updateParams['direccion'] = newValue.isEmpty ? null : newValue;
          break;
      }

      final response = await apiClient.updateProfile(
        apellido: updateParams['apellido'],
        // ✅ REMOVIDO: usuario: updateParams['usuario'],
        campus: updateParams['campus'],
        telefono: updateParams['telefono'],
        direccion: updateParams['direccion'],
      );

      print('✅ Respuesta del servidor: $response');

      // Solo actualizar localmente si la llamada al backend fue exitosa
      if (mounted) {
        setState(() {
          switch (fieldType) {
            case 'apellido':
              _apellido = newValue;
              break;
            case 'usuario':
              _usuario = newValue;
              break;
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
      }
    }
  }

  // Función para generar mensajes específicos de actualización
  String _getUpdateMessage(String fieldType, String newValue) {
    switch (fieldType) {
      case 'apellido':
        return newValue.isEmpty
            ? 'Apellido eliminado correctamente'
            : 'Apellido actualizado a: $newValue';
      case 'usuario':
        return 'Nombre de usuario actualizado a: $newValue';
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
    if (error.contains('USERNAME_TAKEN')) {
      return 'El nombre de usuario ya está en uso';
    } else if (error.contains('TOKEN_INVALID') ||
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