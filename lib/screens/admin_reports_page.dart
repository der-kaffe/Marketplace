import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/report_card.dart';

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
    return ReportCard(
      id: report.id,
      title: report.title,
      description: report.description,
      reporter: report.reporter,
      onView: () {
        // navega al detalle (usa push para mantener historial)
        context.push('/admin/reports/${report.id}');
      },
      onResolve: () {
        // ejemplo: solo simulamos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte ${report.id} marcado como resuelto.')),
        );
        // Aquí puedes llamar tu API para marcar resuelto
      },
      onDelete: () {
        // ejemplo: confirmar eliminación
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Eliminar este reporte?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _reports.removeWhere((r) => r.id == report.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte eliminado.')),
                  );
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
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
          onPressed: () => context.pop(), // <-- vuelve a /admin
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
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