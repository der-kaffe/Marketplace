import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _buildInfoItem(Icons.person, 'Nombre completo', 'Carlos García López'),
              _buildInfoItem(Icons.email, 'Email', 'carlos.garcia@ejemplo.com'),
              _buildInfoItem(Icons.phone, 'Teléfono', '+56 9 1234 5678'),
              _buildInfoItem(Icons.location_on, 'Dirección', 'Av. Alemania 0211, Temuco'),
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
          
          const SizedBox(height: 16),
          
          // Opciones de cuenta
          _buildInfoSection(
            title: 'Mi Cuenta',
            items: [              _buildActionItem(
                icon: Icons.favorite,
                title: 'Mis Favoritos',
                color: AppColors.error,
                onTap: () => _navigateToSection(context, 2),
              ),
              _buildActionItem(
                icon: Icons.notifications,
                title: 'Notificaciones',
                color: AppColors.amarilloPrimario,
                onTap: () => _showFeatureMessage(context, 'Notificaciones'),
              ),
              _buildActionItem(
                icon: Icons.payment,
                title: 'Métodos de Pago',
                color: AppColors.azulPrimario,
                onTap: () => _showFeatureMessage(context, 'Métodos de Pago'),
              ),
              _buildActionItem(
                icon: Icons.settings,
                title: 'Configuración',
                color: AppColors.grisPrimario,
                onTap: () => _showFeatureMessage(context, 'Configuración'),
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
        children: [
          // Foto de perfil
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.blanco,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blanco, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppColors.azulPrimario,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Nombre del usuario
          const Text(
            'Carlos García',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.blanco,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Estado del usuario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amarilloPrimario,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Cliente Premium',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textoOscuro,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas del usuario
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
  
  // Estadísticas del perfil (pedidos, favoritos, etc)
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
              color: AppColors.blanco.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  // Divisor vertical para las estadísticas
  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.blanco.withOpacity(0.3),
    );
  }
  
  // Sección con título y lista de elementos
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
            color: Colors.black.withOpacity(0.05),
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
  
  // Elemento de información personal
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.azulPrimario,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textoOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Elemento de pedido
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
              color: AppColors.azulPrimario.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: AppColors.azulPrimario,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoOscuro,
                      ),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
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
  
  // Elemento de acción de cuenta
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textoOscuro,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grisPrimario,            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar mensajes de características no implementadas
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

  // Método para navegar a diferentes secciones de la app
  void _navigateToSection(BuildContext context, int index) {
    // Actualizar el índice en la pantalla principal
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Volver a la pantalla anterior si es necesario
    }
    // Aquí normalmente usaríamos un gestor de estado como Provider o BLoC
    // para actualizar el índice en MainScreen
    _showFeatureMessage(context, 'Navegando a la sección $index');
  }

  // Método para cerrar la sesión
  void _logout(BuildContext context) {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar la sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el diálogo
                // Navegar a la pantalla de inicio de sesión
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Eliminar todas las rutas anteriores
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
