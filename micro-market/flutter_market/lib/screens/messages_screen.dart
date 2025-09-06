import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fondoClaro,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.message, 
              size: 100, 
              color: AppColors.amarilloPrimario
            ),
            const SizedBox(height: 16),
            Text(
              'Pantalla de Mensajes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.azulPrimario,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: AppColors.blanco,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Nuevo Mensaje'),
            ),
          ],
        ),
      ),
    );
  }
}
