import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_view.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../screens/seller_profile_page.dart';
import '../models/seller_model.dart';

class ChatPage extends StatelessWidget {
  final String userName;
  final String avatar;
  final int destinatarioId;

  const ChatPage({
    Key? key,
    required this.userName,
    required this.avatar,
    required this.destinatarioId,
  }) : super(key: key);  // Método para navegar al perfil del vendedor
  void _navigateToSellerProfile(BuildContext context) async {
    // Navegar directamente con FutureBuilder - sin diálogo de carga
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutureBuilder<Map<String, dynamic>>(
          future: ProductService().getSellerInfo(destinatarioId.toString()),
          builder: (context, snapshot) {
            // Mientras carga, mostrar scaffold con indicador
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.fondoClaro,
                appBar: AppBar(
                  title: const Text('Perfil del Vendedor'),
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset(
                          'assets/logoMarket.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrimario),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Si hay error
            if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(
                backgroundColor: AppColors.fondoClaro,
                appBar: AppBar(
                  title: const Text('Perfil del Vendedor'),
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Datos cargados exitosamente
            final sellerData = snapshot.data!;
            final estadisticas = sellerData['estadisticas'] ?? {};

            final seller = Seller(
              id: sellerData['id']?.toString() ?? destinatarioId.toString(),
              name: sellerData['name'] ?? sellerData['nombre'] ?? userName,
              email: sellerData['correo'] ?? sellerData['email'],
              avatar: sellerData['avatar'] ?? sellerData['fotoPerfilUrl'],
              location: sellerData['campus'] ?? 'Desconocido',
              reputation: (sellerData['reputacion'] is num) 
                  ? (sellerData['reputacion'] as num).toDouble() 
                  : 0.0,
              totalSales: (estadisticas['totalVentas'] as num?)?.toInt() ?? 0,
              activeListings: (estadisticas['publicacionesActivas'] as num?)?.toInt() ?? 0,
              soldListings: (estadisticas['totalVentas'] as num?)?.toInt() ?? 0,
              memberSince: sellerData['miembroDesde'] != null 
                  ? DateTime.tryParse(sellerData['miembroDesde'].toString()) 
                  : null,
            );

            return SellerProfilePage(seller: seller);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            color: AppColors.azulPrimario,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top,
            ),
            child: Row(
              children: [                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () => context.pop(),
                ),                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToSellerProfile(context),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(avatar),
                          onBackgroundImageError: (exception, stackTrace) {},
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  color: AppColors.blanco,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                'Ver perfil',
                                style: TextStyle(
                                  color: AppColors.blanco.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón de llamada - desactivado por ahora
                // IconButton(
                //   icon: Icon(Icons.call, color: AppColors.blanco),
                //   onPressed: () {},
                // ),
              ],
            ),
          ),
          Expanded(
            child: ChatView(
              destinatarioId: destinatarioId,
              destinatarioNombre: userName,
            ),
          ),
        ],
      ),
    );
  }
}
