import 'package:flutter/material.dart';
import '../models/seller_model.dart';
import '../theme/app_colors.dart';

class SellerProfilePage extends StatelessWidget {
  final Seller seller;

  const SellerProfilePage({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(seller.name),
        backgroundColor: AppColors.azulPrimario,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(seller.avatar),
            ),
            const SizedBox(height: 12),
            Text(
              seller.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              seller.location,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoTile("Reputación", seller.reputation.toStringAsFixed(1)),
                _buildInfoTile("Ventas", seller.totalSales.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoTile("Activas", seller.activeListings.toString()),
                _buildInfoTile("Vendidas", seller.soldListings.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
