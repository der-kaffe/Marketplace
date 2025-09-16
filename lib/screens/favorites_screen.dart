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

  @override
  void initState() {
    super.initState();
    // Simular tiempo de carga
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            body: Center(
              child: SpinKitWave(
                color: AppColors.azulPrimario,
                size: 50.0,
              ),
            ),
          )
        : Container(
            color: AppColors.fondoClaro,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite, 
                    size: 100, 
                    color: AppColors.error
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pantalla de Favoritos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.azulPrimario,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grisPrimario,
                      foregroundColor: AppColors.blanco,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Ver Favoritos'),
                  ),
                ],
              ),
            ),
          );
  }
}