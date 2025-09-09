import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFD),
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.65,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Imagen de fondo local
                  Image.asset('assets/universidad.jpg', fit: BoxFit.cover),
                  // 2. Capa de color azul con opacidad
                  Container(color: const Color(0xFF005A8A).withOpacity(0.75)),
                  // 3. Líneas blancas estilo topografía
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marketplace',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3A3A3A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet consectetur.\nLorem id sit',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go('/login');
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFACC15), // Amarillo exacto
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF3A3A3A),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(
        0,
        size.height * 0.82,
      ); // Punto de inicio ajustado para que sea un poco más bajo, preparando el "valle"

    // Primera curva: crea el "valle" a la izquierda
    // Los puntos de control se ajustan para bajar la curva
    path.quadraticBezierTo(
      size.width * 0.3, // Punto de control X
      size.height * 0.70, // Punto de control Y (más bajo para el valle)
      size.width * 0.6, // Punto final X
      size.height *
          0.85, // Punto final Y (altura intermedia antes de la cresta)
    );

    // Segunda curva: crea la "cresta" a la derecha
    // Los puntos de control se ajustan para elevar la curva
    path.quadraticBezierTo(
      size.width *
          0.85, // Punto de control X (cerca del final, empuja la cresta hacia arriba)
      size.height * 0.98, // Punto de control Y (más alto para la cresta)
      size.width, // Llega al borde derecho
      size.height *
          0.85, // Punto final Y (altura final para cerrar la onda, similar al inicio)
    );

    path
      ..lineTo(size.width, 0) // Cierra hacia la esquina superior derecha
      ..close(); // Cierra el camino
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
