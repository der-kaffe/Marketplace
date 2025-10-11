import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../widgets/report_detail_widgets.dart';

class ReportDetailPage extends StatefulWidget {
  final int? reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String reportStatus = 'Pendiente';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    final token = await _authService.getToken();
    final url = Uri.parse('http://10.0.2.2:3001/api/reports/${widget.reportId}');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reportData = data['reporte'];
          reportStatus = _reportData!['estado']['nombre'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar el reporte');
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar detalle del reporte')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_reportData == null) {
      return const Scaffold(
        body: Center(child: Text('No se pudo cargar el reporte')),
      );
    }

    final producto = _reportData!['producto'];
    final usuarioReportado = _reportData!['usuarioReportado'];
    final reportante = _reportData!['reportante'];
    final fecha = _reportData!['fecha'];
    final motivo = _reportData!['motivo'];

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
              Text(
                producto != null ? 'Reporte de producto' : 'Reporte de usuario',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),

              InfoRow(label: 'Motivo', value: motivo),
              InfoRow(label: 'Reportado por', value: '${reportante['nombre']} ${reportante['apellido']}'),
              InfoRow(label: 'Fecha', value: fecha.substring(0, 10)),

              if (producto != null)
                InfoRow(label: 'Producto', value: producto['nombre'])
              else if (usuarioReportado != null)
                InfoRow(label: 'Usuario reportado', value: '${usuarioReportado['nombre']} ${usuarioReportado['apellido']}'),

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

            // Aquí podrías llamar a tu API para actualizar el estado real del reporte
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

            // Aquí podrías implementar la lógica real de eliminación de producto
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

            // Aquí podrías implementar la lógica real de suspensión de usuario
          },
          icon: const Icon(Icons.block),
          label: const Text('Suspender usuario'),
        ),
      ],
    );
  }
}