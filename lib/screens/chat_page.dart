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
  }) : super(key: key);

  // Método para navegar al perfil del vendedor
  void _navigateToSellerProfile(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener información del vendedor
      final sellerData = await ProductService().getSellerInfo(destinatarioId.toString());
      
      // Cerrar indicador de carga
      Navigator.pop(context);

      // Extraer estadísticas
      final estadisticas = sellerData['estadisticas'] ?? {};

      // Crear objeto Seller
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

      // Navegar al perfil
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerProfilePage(seller: seller),
        ),
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      Navigator.pop(context);
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _navigateToSellerProfile(context),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(avatar),
                        onBackgroundImageError: (exception, stackTrace) {},
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              color: AppColors.blanco,
                              fontSize: 18,
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
                    ],
                  ),
                ),
                const Spacer(),
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
