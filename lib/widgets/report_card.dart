import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final int id;
  final String title;
  final String description;
  final String reporter;
  final bool isResolved;
  final Widget? icon;
  final VoidCallback? onView;   
  final VoidCallback? onDelete; 

  const ReportCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.reporter,
    this.isResolved = false, // Por defecto pendiente
    this.icon,
    this.onView,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isResolved ? Colors.green.shade50 : const Color(0xFFFFF4F4);
    final iconColor = isResolved ? Colors.green : Colors.red[700];
    final iconData = isResolved
        ? Icons.check_circle_outline
        : Icons.report_gmailerrorred;

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono lateral
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: icon ??
                    Icon(iconData, color: iconColor, size: 28),
              ),
            ),

            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          isResolved ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reportado por: $reporter',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  color: Colors.blue,
                  tooltip: 'Ver reporte',
                  onPressed: onView,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Eliminar reporte',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}