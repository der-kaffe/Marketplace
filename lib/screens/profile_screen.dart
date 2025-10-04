import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

// Instancia global para manejar Google Sign-In
final GoogleSignIn _googleSignIn = GoogleSignIn();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  
  // Variables para campos editables(por el momento solo teléfono y dirección, los otros no deberian ser editables)
  String _direccion = 'Campus';
  String _telefono = '+56 9 1234 5678';
  
  // Datos del usuario
  String _userName = 'Usuario';
  String _userEmail = 'usuario@ejemplo.com';
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }  // Cargar datos del usuario SOLO desde datos locales guardados
  Future<void> _loadUserData() async {
    try {
      print('🔍 Cargando datos del perfil...');
      final authService = AuthService();
      
      // Obtener datos guardados de Google (modo desarrollo)
      final googleData = await authService.getGoogleUserData();
      print('📱 Datos de Google guardados: $googleData');
      
      if (googleData != null) {
        setState(() {
          _userName = googleData['name'] ?? 'Usuario';
          _userEmail = googleData['email'] ?? 'usuario@ejemplo.com';
          _userPhotoUrl = googleData['photoUrl'];
        });
        print('✅ Datos cargados exitosamente: $_userName, $_userEmail');
      } else {
        print('⚠️ No se encontraron datos de Google, usando valores por defecto');
        setState(() {
          _userName = 'Usuario Invitado';
          _userEmail = 'invitado@ejemplo.com';
          _userPhotoUrl = null;
        });
      }
      
      // Intentar obtener datos del usuario desde AuthService si están disponibles
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        print('👤 Usuario actual del AuthService: ${currentUser.name}');
        setState(() {
          _userName = currentUser.name.isNotEmpty ? currentUser.name : _userName;
          _userEmail = currentUser.email.isNotEmpty ? currentUser.email : _userEmail;
        });
      }
      
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      // Mantener valores por defecto seguros
      setState(() {
        _userName = 'Usuario';
        _userEmail = 'usuario@ejemplo.com';
        _userPhotoUrl = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🏁 Carga de perfil completada');
    }
  }
  // Método para refrescar los datos del usuario (simplificado)
  Future<void> _refreshUserData() async {
    print('🔄 Refrescando datos del perfil...');
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
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
                    _buildInfoItem(
                        Icons.person, 'Nombre completo', _userName),
                    _buildInfoItem(Icons.email, 'Email', _userEmail),
                    _buildActionItem(
                      icon: Icons.refresh,
                      title: 'Actualizar datos de perfil',
                      color: AppColors.azulPrimario,
                      onTap: _refreshUserData,
                    ),
                    _buildEditableInfoItem(Icons.phone, 'Teléfono', _telefono, () => _editField('teléfono')),
                    _buildEditableInfoItem(
                        Icons.location_on, 'Campus/Dirección', _direccion, () => _editField('dirección')),
                  ],
                ),

                const SizedBox(height: 16),

                // Historial de pedidos
                _buildInfoSection(
                  title: 'Mis Pedidos',
                  items: [
                    _buildOrderItem(
                      orderNumber: '#12345',
                      date: '30 ago. 2025',
                      status: 'Entregado',
                      amount: 47990,
                      statusColor: Colors.green,
                    ),
                    _buildOrderItem(
                      orderNumber: '#12340',
                      date: '25 ago. 2025',
                      status: 'En proceso',
                      amount: 89990,
                      statusColor: AppColors.amarilloPrimario,
                    ),
                    _buildOrderItem(
                      orderNumber: '#12335',
                      date: '20 ago. 2025',
                      status: 'Cancelado',
                      amount: 25990,
                      statusColor: AppColors.error,
                    ),
                  ],
                ),

                const SizedBox(height: 16),                // Opciones de cuenta
                _buildInfoSection(
                  title: 'Mi Cuenta',
                  items: [
                    _buildActionItem(
                      icon: Icons.favorite,
                      title: 'Mis Favoritos',
                      color: AppColors.error,
                      onTap: () => _navigateToSection(context, 2),
                    ),                    _buildActionItem(
                      icon: Icons.notifications,
                      title: 'Notificaciones',
                      color: AppColors.amarilloPrimario,
                      onTap: () => _showFeatureMessage(context, 'Notificaciones'),
                    ),
                    _buildActionItem(
                      icon: Icons.help_outline,
                      title: 'Ayuda y Soporte',
                      color: AppColors.azulPrimario,
                      onTap: () => _showFeatureMessage(context, 'Ayuda y Soporte'),
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
        children: [          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.blanco,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blanco, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
              _buildStatistic('12', 'Pedidos'),
              _verticalDivider(),
              _buildStatistic('5', 'Favoritos'),
              _verticalDivider(),
              _buildStatistic('3', 'Reseñas'),
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
              color: AppColors.blanco.withValues(alpha: 0.8),
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
      color: AppColors.blanco.withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withValues(alpha: 0.1),
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
              color: AppColors.azulPrimario.withValues(alpha: 0.1),
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
                    Text('\$${amount.toStringAsFixed(0)}',
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
                          color: statusColor.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
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
        );      },
    );
  }

  // Widget para campos editables
  Widget _buildEditableInfoItem(IconData icon, String label, String value, VoidCallback onEdit) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.azulPrimario.withValues(alpha: 0.1),
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
  }

  // Método para editar campos
  void _editField(String fieldType) {
    String currentValue = fieldType == 'teléfono' ? _telefono : _direccion;
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar $fieldType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fieldType == 'dirección') ...[
                const Text(
                  'Selecciona tu ubicación:',
                  style: TextStyle(fontSize: 14, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 12),                DropdownButtonFormField<String>(
                  value: _getCampusDropdownValue(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Ubicación',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Campus', child: Text('Campus UCT - Sede Principal')),
                    DropdownMenuItem(value: 'Campus Norte', child: Text('Campus Norte UCT')),
                    DropdownMenuItem(value: 'Campus San Francisco', child: Text('Campus San Francisco')),
                    DropdownMenuItem(value: 'Campus Menchaca lira', child: Text('Campus Menchaca lira')),
                    DropdownMenuItem(value: 'Campus Rivas del canto', child: Text('Campus Rivas del canto')),
                    DropdownMenuItem(value: 'Dirección personalizada', child: Text('Dirección personalizada')),
                  ],
                  onChanged: (value) {
                    if (value != 'Dirección personalizada') {
                      controller.text = value ?? 'Campus';
                    } else {
                      controller.text = _direccion.contains('Campus') ? '' : _direccion;
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: fieldType == 'teléfono' ? 'Número de teléfono' : 'Dirección detallada',
                  hintText: fieldType == 'teléfono' 
                    ? '+56 9 1234 5678' 
                    : 'Ej: Av. Alemania 0211, Temuco',
                ),
                keyboardType: fieldType == 'teléfono' ? TextInputType.phone : TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (fieldType == 'teléfono') {
                    _telefono = controller.text.trim();
                  } else {
                    _direccion = controller.text.trim();
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$fieldType actualizado correctamente'),
                    backgroundColor: AppColors.exito,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );      },
    );
  }
  // Método para obtener el valor correcto del dropdown de campus
  String _getCampusDropdownValue() {
    final campusOptions = [
      'Campus',
      'Campus Norte',
      'Campus San Francisco', 
      'Campus Menchaca lira',
      'Campus Rivas del canto'
    ];
    
    if (campusOptions.contains(_direccion)) {
      return _direccion;
    }
    return 'Dirección personalizada';
  }
}