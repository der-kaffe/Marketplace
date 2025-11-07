import 'package:flutter/material.dart';
import '../models/seller_model.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';

class SellerProfilePage extends StatelessWidget {
  final Seller seller;

  const SellerProfilePage({super.key, required this.seller});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      appBar: AppBar(
        title: const Text('Perfil del Vendedor'),
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
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
                  _buildProfileAvatar(),
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

            // Estadísticas del vendedor mejoradas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Primera fila - Reputación y Ventas Totales
                  _buildBadgeRow([
                    _buildStatBadge(
                      Icons.star_rounded, 
                      "Reputación", 
                      seller.reputation > 0 ? seller.reputation.toStringAsFixed(1) : "Nuevo",
                      color: seller.reputation >= 4.0 ? Colors.green : 
                             seller.reputation >= 3.0 ? Colors.orange : 
                             seller.reputation > 0 ? Colors.red : Colors.grey
                    ),
                    _buildStatBadge(
                      Icons.trending_up, 
                      "Ventas Totales", 
                      seller.totalSales.toString(),
                      color: AppColors.azulPrimario
                    ),
                  ]),
                  const SizedBox(height: 12),
                  
                  // Segunda fila - Publicaciones Activas y Experiencia
                  _buildBadgeRow([
                    _buildStatBadge(
                      Icons.inventory_2_outlined, 
                      "Activas", 
                      seller.activeListings.toString(),
                      color: Colors.green
                    ),
                    _buildStatBadge(
                      Icons.schedule, 
                      "Miembro desde", 
                      _formatMemberSince(seller.memberSince),
                      color: Colors.indigo
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Sección de información adicional
            _buildInfoSection(),
            
            // Espaciado adicional al final para mejor UX
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }  // Badge con ícono y texto mejorado - versión responsive
  Widget _buildStatBadge(IconData icon, String label, String value, {Color? color}) {
    final badgeColor = color ?? AppColors.azulPrimario;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: badgeColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }// Fila de 2 badges con manejo mejorado del overflow
  Widget _buildBadgeRow(List<Widget> children) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ))
            .toList(),
      ),
    );
  }

  // 📸 Avatar del vendedor con manejo mejorado de imágenes
  Widget _buildProfileAvatar() {
    String? avatarUrl;
    
    // Construir URL completa si es necesario
    if (seller.avatar != null && seller.avatar!.isNotEmpty) {
      if (seller.avatar!.startsWith('http')) {
        // URL completa
        avatarUrl = seller.avatar!;
      } else {
        // URL relativa - construir URL completa
        avatarUrl = '${getDefaultBaseUrl()}${seller.avatar!}';
      }
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            : _buildFallbackAvatar(),
      ),
    );
  }
  // 👤 Avatar por defecto cuando no hay imagen
  Widget _buildFallbackAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.grisPrimario.withAlpha((0.1 * 255).toInt()),
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.azulPrimario,
      ),
    );
  }

  // 📅 Formatear fecha de miembro desde
  String _formatMemberSince(DateTime? memberSince) {
    if (memberSince == null) return 'N/A';
    
    final now = DateTime.now();
    final difference = now.difference(memberSince);
    
    if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}a';
    }
  }
  // ℹ️ Sección de información adicional del vendedor - versión mejorada
  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.azulPrimario, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Información del Vendedor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(Icons.school, 'Campus', seller.location),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'Usuario', '@${seller.id}'),
          if (seller.memberSince != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today, 
              'Miembro desde', 
              '${seller.memberSince!.day}/${seller.memberSince!.month}/${seller.memberSince!.year}'
            ),
          ],
        ],
      ),
    );
  }
  // 📋 Fila de información individual - versión responsive
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.azulPrimario.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.azulPrimario),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.azulOscuro,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
