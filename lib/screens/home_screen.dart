import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../widgets/product_detail_modal.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  final List<Product> _products = [];
  bool _isLoading = false;
  int _page = 0;
  final int _limit = 4; // productos por carga (matching original count)

  @override
  void initState() {
    super.initState();
    _loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final newProducts =
        await _productService.fetchProducts(page: _page, limit: _limit);
        
    setState(() {
      _products.addAll(newProducts);
      _page++;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _products.isEmpty) {
      return const Scaffold(
        body: Center(
          child: SpinKitWave(
            color: AppColors.azulPrimario,
            size: 50.0,
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🔹 Banner promocional
          _buildPromoBanner(context),

          const SizedBox(height: 24),

          // 🔹 Categorías
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  _showNotImplementedMessage(context, 'Ver todas las categorías');
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryCard(
                  icon: Icons.sports_soccer,
                  title: 'Deportes',
                  color: Colors.blue,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Deportes'),
                ),
                CategoryCard(
                  icon: Icons.devices,
                  title: 'Electrónica',
                  color: AppColors.amarilloPrimario,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Electrónica'),
                ),
                CategoryCard(
                  icon: Icons.checkroom,
                  title: 'Ropa',
                  color: Colors.orange,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Ropa'),
                ),
                CategoryCard(
                  icon: Icons.diamond,
                  title: 'Joyas',
                  color: Colors.purple,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Joyas'),
                ),
                CategoryCard(
                  icon: Icons.spa,
                  title: 'Belleza',
                  color: Colors.pink,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Belleza'),
                ),
                CategoryCard(
                  icon: Icons.chair,
                  title: 'Hogar',
                  color: Colors.green,
                  onTap: () => _showNotImplementedMessage(context, 'Categoría: Hogar'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 🔹 Productos destacados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productos destacados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  _showNotImplementedMessage(context, 'Ver todos los productos');
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              // 🔹 Ajuste dinámico para pantallas pequeñas
              childAspectRatio: screenWidth < 380 ? 0.65 : 0.70,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _products.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _products.length) {
                return const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.azulPrimario,
                    size: 40.0,
                  ),
                );
              }

              final product = _products[index];
              return ProductCard(
                imageUrl: product.imageUrl,
                title: product.title,
                description: product.description,
                price: product.price,
                isAvailable: product.isAvailable,
                onToggleVisibility: () {
                  setState(() {
                    _products[index] = product.copyWith(
                      isAvailable: !product.isAvailable,
                    );
                  });
                },
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProductDetailModal(product: product),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // 🔹 Promociones
          const Text(
            'Promociones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

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

  // Widget para el banner promocional (original)
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
  
  // Widget para las tarjetas de promoción (original)
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