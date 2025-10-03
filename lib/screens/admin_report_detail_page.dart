import 'package:flutter/material.dart';
import '../widgets/report_detail_widgets.dart';

class ReportDetailPage extends StatefulWidget {
  final int? reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String reportStatus = 'Pendiente';
  final TextEditingController _notesController = TextEditingController();

  final report = {
    'title': 'Contenido inapropiado',
    'description': 'Se reportó una publicación ofensiva que viola las normas de la comunidad.',
    'reporter': 'Usuario1',
    'fecha': '2025-09-08',
    'relacionadoCon': 'Publicación: "Oferta de trabajo falsa"',
    'evidencia': 'https://picsum.photos/400/300',
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // título principal
              Text(
                report['title']!,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),

              // info básica
              InfoRow(label: 'Descripción', value: report['description']!),
              InfoRow(label: 'Reportado por', value: report['reporter']!),
              InfoRow(label: 'Fecha', value: report['fecha']!),
              InfoRow(label: 'Relacionado con', value: report['relacionadoCon']!),

              const SizedBox(height: 20),

              Text('Evidencia:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              EvidenceViewer(imageUrl: report['evidencia']!),

              const SizedBox(height: 24),
              _buildStatusToggle(context),

              const SizedBox(height: 24),
              _buildActionButtons(),

              const SizedBox(height: 24),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas internas',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // aquí se guarda en tiempo real si quieres enviar luego a la API
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estado: $reportStatus',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: reportStatus == 'Pendiente' ? Colors.green : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            setState(() {
              reportStatus = (reportStatus == 'Pendiente') ? 'Revisado' : 'Pendiente';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  reportStatus == 'Revisado'
                      ? 'Reporte marcado como revisado'
                      : 'Reporte marcado como pendiente',
                ),
              ),
            );
          },
          child: Text(
            reportStatus == 'Pendiente' ? 'Marcar como revisado' : 'Marcar como pendiente',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publicación eliminada (simulado)')),
            );
          },
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar publicación'),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario suspendido (simulado)')),
            );
          },
          icon: const Icon(Icons.block),
          label: const Text('Suspender usuario'),
        ),
      ],
    );
  }
}
