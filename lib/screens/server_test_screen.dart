import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/config/api_config.dart';

class ServerTestScreen extends StatefulWidget {
  const ServerTestScreen({Key? key}) : super(key: key);

  @override
  _ServerTestScreenState createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  final _emailController = TextEditingController(text: 'test@uct.cl');
  final _passwordController = TextEditingController(text: '123456');
  
  bool _isLoading = false;
  String _testResults = '';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog('🔧 Pantalla de pruebas del servidor iniciada');
    _addLog('🌐 URL del servidor: ${ApiConfig.baseUrl}');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
      _logs.clear();
    });

    _addLog('🧪 Iniciando pruebas del servidor...');
    
    try {
      final authService = AuthService();
        // Test 1: Health Check
      _addLog('1️⃣ Probando health check...');
      try {
        final healthResponse = await authService.apiClient.health();
        if (healthResponse['ok'] == true) {
          _addLog('✅ Health check exitoso');
          _addLog('📊 Estado BD: ${healthResponse['database']}');
        } else {
          _addLog('❌ Health check falló');
        }
      } catch (e) {
        _addLog('❌ Error en health check: $e');
      }

      // Test 2: Login
      _addLog('2️⃣ Probando login...');
      try {
        final loginResponse = await authService.loginWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        
        if (loginResponse.ok && loginResponse.user != null) {
          _addLog('✅ Login exitoso');
          _addLog('👤 Usuario: ${loginResponse.user!.name}');
          _addLog('🏷️ Rol: ${loginResponse.user!.role}');
          _addLog('🎓 Campus: ${loginResponse.user!.campus ?? 'N/A'}');
          _addLog('⭐ Reputación: ${loginResponse.user!.reputation ?? 0}');
          _addLog('🎫 Token obtenido: ${loginResponse.token != null ? 'Sí' : 'No'}');
          
          setState(() {
            _testResults = 'Conexión exitosa con el backend! ✅';
          });
        } else {
          _addLog('❌ Login falló: ${loginResponse.message}');
          setState(() {
            _testResults = 'Error en login: ${loginResponse.message}';
          });
        }
      } catch (e) {
        _addLog('❌ Error en login: $e');
        setState(() {
          _testResults = 'Error de conexión: $e';
        });
      }

      _addLog('🏁 Pruebas completadas');
      
    } catch (e) {
      _addLog('💥 Error general: $e');
      setState(() {
        _testResults = 'Error general: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas del Servidor'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del servidor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Configuración del Servidor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('URL: ${ApiConfig.baseUrl}'),
                    Text('Health: ${ApiConfig.healthEndpoint}'),
                    Text('Login: ${ApiConfig.loginEndpoint}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Credenciales de prueba
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔐 Credenciales de Prueba',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón de prueba
            ElevatedButton(
              onPressed: _isLoading ? null : _testServerConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Probando...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('🧪 Probar Conexión', style: TextStyle(color: Colors.white)),
            ),
            
            const SizedBox(height: 16),
            
            // Resultados
            if (_testResults.isNotEmpty)
              Card(
                color: _testResults.contains('exitosa') ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _testResults,
                    style: TextStyle(
                      color: _testResults.contains('exitosa') ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Logs de Prueba',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView(
                            children: _logs.map((log) => Text(
                              log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
