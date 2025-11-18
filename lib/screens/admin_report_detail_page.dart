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
    final url =
        Uri.parse('http://186.64.113.170:3001/api/reports/${widget.reportId}');

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
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Título
            Card(
              color: Colors.redAccent.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      producto != null ? Icons.shopping_cart : Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        producto != null
                            ? 'Reporte de Producto'
                            : 'Reporte de Usuario',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Información del reporte
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InfoRow(
                        label: 'Motivo',
                        value: motivo,
                        icon: Icons.report_problem),
                    const Divider(),
                    InfoRow(
                        label: 'Reportado por',
                        value:
                            '${reportante['nombre']} ${reportante['apellido']}',
                        icon: Icons.person),
                    const Divider(),
                    InfoRow(
                        label: 'Fecha',
                        value: fecha.substring(0, 10),
                        icon: Icons.calendar_today),
                    const Divider(),
                    if (producto != null)
                      InfoRow(
                          label: 'Producto',
                          value: producto['nombre'],
                          icon: Icons.shopping_bag)
                    else if (usuarioReportado != null)
                      InfoRow(
                          label: 'Usuario reportado',
                          value:
                              '${usuarioReportado['nombre']} ${usuarioReportado['apellido']}',
                          icon: Icons.person_outline),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Estado del reporte
            Card(
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Estado actual:',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: reportStatus == 'Pendiente'
                            ? Colors.orangeAccent
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _toggleStatus,
                      icon: Icon(reportStatus == 'Pendiente'
                          ? Icons.pending_actions
                          : Icons.check_circle),
                      label: Text(reportStatus == 'Pendiente'
                          ? 'Marcar como revisado'
                          : 'Marcar como pendiente'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    final nuevoEstadoId = reportStatus == 'Pendiente' ? 2 : 1;
    final token = await _authService.getToken();

    final url =
        Uri.parse('http://186.64.113.170:3001/api/reports/${widget.reportId}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estadoId': nuevoEstadoId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          reportStatus = reportStatus == 'Pendiente' ? 'Revisado' : 'Pendiente';
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
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al actualizar estado');
      }
    } catch (e) {
      print('❌ Error actualizando estado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el estado')),
      );
    }
  }
}
