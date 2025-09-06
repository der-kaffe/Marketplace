import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner promocional
            _buildPromoBanner(context),
            
            const SizedBox(height: 24),
            
            // Categorías
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categorías',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Implementar navegación a todas las categorías
                    _showNotImplementedMessage(context, 'Ver todas las categorías');
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Lista horizontal de categorías
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CategoryCard(
                    icon: Icons.fastfood,
                    title: 'Comidas',
                    color: AppColors.amarilloPrimario,
                    onTap: () => _showNotImplementedMessage(context, 'Categoría: Comidas'),
                  ),
                  CategoryCard(
                    icon: Icons.local_drink,
                    title: 'Bebidas',
                    color: Colors.orange,
                    onTap: () => _showNotImplementedMessage(context, 'Categoría: Bebidas'),
                  ),
                  CategoryCard(
                    icon: Icons.breakfast_dining,
                    title: 'Snacks',
                    color: Colors.green,
                    onTap: () => _showNotImplementedMessage(context, 'Categoría: Snacks'),
                  ),
                  CategoryCard(
                    icon: Icons.cake,
                    title: 'Postres',
                    color: Colors.purple,
                    onTap: () => _showNotImplementedMessage(context, 'Categoría: Postres'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Productos destacados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Productos destacados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Implementar navegación a todos los productos
                    _showNotImplementedMessage(context, 'Ver todos los productos');
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Productos destacados en grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [                ProductCard(
                  imageUrl: 'https://via.placeholder.com/150',
                  title: 'Sandwich Italiano',
                  description: 'Delicioso sandwich con ingredientes frescos',
                  price: 2500,
                  onTap: () => _showNotImplementedMessage(context, 'Producto: Sandwich Italiano'),
                ),
                ProductCard(
                  imageUrl: 'https://via.placeholder.com/150',
                  title: 'Café Americano',
                  description: 'Café de grano selecto, recién molido',
                  price: 1800,
                  onTap: () => _showNotImplementedMessage(context, 'Producto: Café Americano'),
                ),
                ProductCard(
                  imageUrl: 'https://via.placeholder.com/150',
                  title: 'Ensalada César',
                  description: 'Ensalada fresca con aderezo especial',
                  price: 3200,
                  onTap: () => _showNotImplementedMessage(context, 'Producto: Ensalada César'),
                ),
                ProductCard(
                  imageUrl: 'https://via.placeholder.com/150',
                  title: 'Jugo Natural',
                  description: 'Jugo de frutas naturales sin azúcar añadida',
                  price: 1500,
                  onTap: () => _showNotImplementedMessage(context, 'Producto: Jugo Natural'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Promociones
            const Text(
              'Promociones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Banner de promociones
            _buildPromotionCard(
              context,
              'Desayuno Completo',
              '20% de descuento',
              AppColors.amarilloPrimario,
            ),
            
            const SizedBox(height: 10),
            
            _buildPromotionCard(
              context,
              'Combo Almuerzo',
              '2x1 los miércoles',
              AppColors.azulPrimario,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Método para mostrar mensaje cuando una función aún no está implementada
  void _showNotImplementedMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.azulPrimario,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Widget para el banner promocional
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.azulPrimario, Color(0xFF003F7F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  'https://via.placeholder.com/200',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¡Bienvenido a MicroMarket!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Encuentra los mejores productos de la UCT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Implementar acción de explorar
                    _showNotImplementedMessage(context, 'Explorar productos');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amarilloPrimario,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Explorar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para las tarjetas de promoción
  Widget _buildPromotionCard(BuildContext context, String title, String subtitle, Color color) {
    return GestureDetector(
      onTap: () => _showNotImplementedMessage(context, 'Promoción: $title'),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.local_offer,
                      color: color,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

