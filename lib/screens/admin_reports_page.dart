import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/report_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ReportItem {
  final int id;
  final String title;
  final String description;
  final String reporter;
  final String estadoNombre; // Nuevo campo

  ReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.reporter,
    required this.estadoNombre,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    String title = '';
    String description = '';
    if (json['producto'] != null) {
      title = json['producto']['nombre'] ?? 'Producto reportado';
      description = json['motivo'] ?? '';
    } else if (json['usuarioReportado'] != null) {
      title = '${json['usuarioReportado']['nombre']} ${json['usuarioReportado']['apellido']}';
      description = json['motivo'] ?? '';
    } else {
      title = 'Reporte';
      description = json['motivo'] ?? '';
    }

    String reporterName = '';
    if (json['reportante'] != null) {
      final rep = json['reportante'];
      reporterName = '${rep['nombre']} ${rep['apellido']}';
    }

    // Parsear el estado, poner "Pendiente" si no viene
    String estado = 'Pendiente';
    if (json['estado'] != null && json['estado']['nombre'] != null) {
      estado = json['estado']['nombre'];
    }

    return ReportItem(
      id: json['id'],
      title: title,
      description: description,
      reporter: reporterName,
      estadoNombre: estado,
    );
  }
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<ReportItem> _reports = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  final String apiBaseUrl = 'http://10.0.2.2:3001/api/reports';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      print("TOKEN: $token");

      final response = await http.get(
        Uri.parse(apiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsJson = data['reportes'] ?? [];

        setState(() {
          _reports = reportsJson.map((json) => ReportItem.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el servidor')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshReports() async {
    await _fetchReports();
  }

  // Nuevo método para actualizar solo un reporte en la lista
  Future<void> _updateReportStatus(int reportId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('$apiBaseUrl/$reportId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedReport = ReportItem.fromJson(data['reporte']);

        setState(() {
          final index = _reports.indexWhere((r) => r.id == reportId);
          if (index != -1) {
            _reports[index] = updatedReport;
          }
        });
      }
    } catch (e) {
      print('Error actualizando reporte localmente: $e');
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola Administrador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Panel de reportes',
                style: TextStyle(fontSize: 13, color: Color(0xFFF6B400)),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDEBDF), Color(0xFFFFF7F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withAlpha(31), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_reports.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Número de\nReportes',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportItem report) {
    bool isResolved = report.estadoNombre.toLowerCase() == 'resuelto';
    bool isReviewed = report.estadoNombre.toLowerCase() == 'revisado';
    bool isPending = report.estadoNombre.toLowerCase() == 'pendiente';

    IconData iconData;
    Color iconColor;

    if (isResolved) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isReviewed) {
      iconData = Icons.check_circle_outline;
      iconColor = Colors.orange;
    } else if (isPending) {
      iconData = Icons.pending;
      iconColor = Colors.red;
    } else {
      iconData = Icons.report;
      iconColor = Colors.grey;
    }

    return ReportCard(
      id: report.id,
      title: report.title,
      description: report.description,
      reporter: report.reporter,
      isResolved: isResolved,
      icon: Icon(iconData, color: iconColor),
      onView: () async {
        // Espero el resultado de la página detalle (bool: true si hubo cambio)
        final result = await context.push<bool>('/admin/reports/${report.id}');
        if (result == true) {
          await _updateReportStatus(report.id);
        }
      },
      onDelete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminar reporte ${report.id}')),
        );
        // Agregá tu lógica de eliminación real aquí
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de Reportes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshReports,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const Divider(height: 0.5),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: Text(
                          'Lista de reportes',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20, top: 6),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(_reports[index]);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}