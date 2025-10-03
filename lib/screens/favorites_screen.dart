import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> favoriteItems = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;

        favoriteItems = [
          {
            'id': 1,
            'title': 'Calculadora Científica',
            'image': 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
            'price': '\$15.000',
          },
          {
            'id': 2,
            'title': 'Libro de Física 1',
            'image': 'https://picsum.photos/150',
            'price': '\$8.000',
          },
          {
            'id': 3,
            'title': 'Mochila Escolar',
            'image': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=150&q=80',
            'price': '\$25.000',
          },
          {
            'id': 4,
            'title': 'Audífonos Bluetooth',
            'image': 'https://picsum.photos/150',
            'price': '\$35.000',
          },
          {
            'id': 5,
            'title': 'Libro de Cálculo',
            'image': 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=150&q=80',
            'price': '\$10.000',
          },
          {
            'id': 6,
            'title': 'Set de útiles de dibujo',
            'image': 'https://picsum.photos/150',
            'price': '\$12.000',
          },
        ];

      });
    });
  }

  void _removeFavorite(int id) {
    setState(() {
      favoriteItems.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 50.0,
              ),
            )
          : favoriteItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = favoriteItems[index];
                    return _buildFavoriteCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: AppColors.grisPrimario),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos aún',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.azulPrimario,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos a favoritos para verlos aquí',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'],
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(item['title']),
        subtitle: Text(item['price']),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _removeFavorite(item['id']),
        ),
      ),
    );
  }
}