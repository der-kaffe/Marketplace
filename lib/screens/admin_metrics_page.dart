// lib/pages/admin_metrics_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdminMetricsPage extends StatefulWidget {
  const AdminMetricsPage({super.key});

  @override
  State<AdminMetricsPage> createState() => _AdminMetricsPageState();
}

class _AdminMetricsPageState extends State<AdminMetricsPage> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  Map<String, dynamic>? _metrics;
  final String apiUrl = 'http://10.0.2.2:3001/api/admin/metrics';

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _loading = true);
    try {
      final token = await _auth.getToken();
      final resp = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() => _metrics = data['metrics'] ?? {});
      } else {
        debugPrint('Metrics error: ${resp.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando métricas (${resp.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _metricCard(String title, String value, {IconData? icon, Color? color}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                backgroundColor: (color ?? Colors.blue).withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
            if (icon != null) const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNewUsersList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Sin datos recientes'));
    }
    return Column(
      children: list.map<Widget>((e) {
        final day = e['day'] ?? e['day'].toString();
        final count = e['count'] ?? e['cnt'] ?? 0;
        return ListTile(
          leading: Icon(Icons.calendar_today, size: 18),
          title: Text(day),
          trailing: Text('$count'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas del Sistema'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchMetrics,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _metricCard('Usuarios totales', '${_metrics?['totalUsers'] ?? '-'}', icon: Icons.people, color: Colors.blue),
                        _metricCard('Usuarios activos 30d', '${_metrics?['activeUsers30d'] ?? '-'}', icon: Icons.flash_on, color: Colors.teal),
                        _metricCard('Productos', '${_metrics?['totalProducts'] ?? '-'}', icon: Icons.shopping_bag, color: Colors.purple),
                        _metricCard('Publicaciones', '${_metrics?['totalPublications'] ?? '-'}', icon: Icons.post_add, color: Colors.indigo),
                        _metricCard('Reportes abiertos', '${_metrics?['openReports'] ?? '-'}', icon: Icons.report, color: Colors.red),
                        _metricCard('Transacciones completadas', '${_metrics?['completedTransactions'] ?? '-'}', icon: Icons.check_circle, color: Colors.green),
                        _metricCard('Mensajes 7d', '${_metrics?['messagesLast7d'] ?? '-'}', icon: Icons.message, color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Nuevos usuarios (últimos 7 días)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildNewUsersList(_metrics?['newUsersByDay'] ?? []),
                  ],
                ),
              ),
      ),
    );
  }
}