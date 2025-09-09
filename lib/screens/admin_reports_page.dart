import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportItem {
  final int id;
  final String title;
  final String description;
  final String reporter;

  ReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.reporter,
  });
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final List<ReportItem> _reports = [
    ReportItem(id: 1, title: 'Contenido inapropiado', description: 'Se reportó una publicación ofensiva.', reporter: 'Usuario1'),
    ReportItem(id: 2, title: 'Spam', description: 'Un usuario está haciendo spam de links.', reporter: 'Usuario2'),
    ReportItem(id: 3, title: 'Estafa', description: 'Se sospecha de una estafa en un producto.', reporter: 'Usuario3'),
  ];

  Future<void> _refreshReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Aquí puedes hacer una llamada real a tu API
  }



  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hola Administrador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_reports.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4), // rojo claro
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.report_gmailerrorred, color: Colors.red[700], size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reportado por: ${report.reporter}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
            tooltip: 'Ver detalles',
            onPressed: () {
              context.push('/admin/reports/${report.id}');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshReports,
          child: Column(
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