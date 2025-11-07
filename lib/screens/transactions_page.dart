import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  List<dynamic> _purchases = [];
  List<dynamic> _sales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchTransactions('purchases'), _fetchTransactions('sales')]);
  }

  Future<void> _fetchTransactions(String type) async {
    try {
      setState(() => _loading = true);

      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3001/api/transactions/$type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (type == 'purchases') {
            _purchases = data['purchases'] ?? [];
          } else {
            _sales = data['sales'] ?? [];
          }
        });
      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error cargando $type: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmTransaction(int id, String action) async {
    final authService = AuthService();
    final token = await authService.getToken();

    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:3001/api/transactions/$id/$action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Confirmación exitosa')),
        );
        _loadAll(); // recarga listas
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error al confirmar')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error de conexión: $e')),
      );
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, bool isSeller) {
    final producto = tx['producto']?['nombre'] ?? 'Producto';
    final fecha = tx['fecha'] ?? '';
    final cantidad = tx['cantidad'] ?? 1;
    final total = tx['precioTotal']?.toString() ?? '0.00';
    final comprador = tx['comprador']?['nombre'] ?? '';
    final vendedor = tx['vendedor']?['nombre'] ?? '';

    final confirmVendedor = tx['confirmacionVendedor'] ?? false;
    final confirmComprador = tx['confirmacionComprador'] ?? false;
    final completada = confirmVendedor && confirmComprador;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Fecha: $fecha', style: const TextStyle(fontSize: 13)),
            Text('Cantidad: $cantidad | Total: \$$total'),
            const SizedBox(height: 8),
            Text(isSeller
                ? 'Comprador: $comprador'
                : 'Vendedor: $vendedor'),
            const SizedBox(height: 8),
            if (completada)
              const Text(
                '✅ Transacción completada',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSeller && !confirmVendedor)
                    ElevatedButton(
                      onPressed: () =>
                          _confirmTransaction(tx['id'], 'confirm-delivery'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: const Text('Confirmar Entrega'),
                    ),
                  if (!isSeller && !confirmComprador)
                    ElevatedButton(
                      onPressed: () =>
                          _confirmTransaction(tx['id'], 'confirm-receipt'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),
                      child: const Text('Confirmar Recibo'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> data, bool isSeller) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (data.isEmpty) {
      return const Center(child: Text('No hay transacciones registradas.'));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        children: data
            .map((tx) => _buildTransactionCard(tx, isSeller))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Transacciones'),
        backgroundColor: const Color(0xFF00A8E8),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Compras', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Mis Ventas', icon: Icon(Icons.sell)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_purchases, false),
          _buildTabContent(_sales, true),
        ],
      ),
    );
  }
}