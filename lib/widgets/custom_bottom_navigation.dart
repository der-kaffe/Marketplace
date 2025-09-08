import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onNewPost; // 👈 nuevo callback

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onNewPost, // 👈 requerido
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.azulPrimario,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(icon: Icons.home, label: 'Home', isSelected: currentIndex == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.message, label: 'Mensajes', isSelected: currentIndex == 1, onTap: () => onTap(1)),

            // 👇 Botón central grande "Nuevo"
            _NewPostButton(onTap: onNewPost),

            _NavItem(icon: Icons.favorite, label: 'Favoritos', isSelected: currentIndex == 2, onTap: () => onTap(2)),
            _NavItem(icon: Icons.person, label: 'Perfil', isSelected: currentIndex == 3, onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

class _NewPostButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewPostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12), // levantado
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.amarilloPrimario,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: const Icon(Icons.add, size: 30, color: AppColors.azulPrimario),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.amarilloPrimario : AppColors.blanco;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSelected ? 28 : 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: isSelected ? 12 : 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
