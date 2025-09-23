import 'package:flutter/material.dart';
import '../models/seller_model.dart';
import '../theme/app_colors.dart';

class SellerProfilePage extends StatelessWidget {
  final Seller seller;

  const SellerProfilePage({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      appBar: AppBar(
        title: Text('Perfil del Vendedor'),
        backgroundColor: AppColors.azulPrimario,
      ),
      body: Column(
        children: [
          // 🟦 Banner superior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                AppColors.azulPrimario,
                AppColors.azulPrimario.withValues(alpha: 204),
              ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(seller.avatar),
                ),
                const SizedBox(height: 12),
                Text(
                  seller.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  seller.location,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Datos del vendedor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildBadgeRow([
                  _buildStatBadge(Icons.star, "Reputación", seller.reputation.toStringAsFixed(1)),
                  _buildStatBadge(Icons.shopping_cart, "Ventas", seller.totalSales.toString()),
                ]),
                const SizedBox(height: 16),
                _buildBadgeRow([
                  _buildStatBadge(Icons.list_alt, "Activas", seller.activeListings.toString()),
                  _buildStatBadge(Icons.check_circle, "Vendidas", seller.soldListings.toString()),
                ]),
              ],
            ),
          ),

        ],
      ),
    );
  }

  // Badge con ícono y texto
  Widget _buildStatBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 20),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.azulPrimario, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulOscuro,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fila de 2 badges
  Widget _buildBadgeRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children
          .map((child) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: child,
              )))
          .toList(),
    );
  }
}
