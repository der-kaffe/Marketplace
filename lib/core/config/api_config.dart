class ApiConfig {
  // Configuración para desarrollo local
  static const String _localBaseUrl = 'http://localhost:3001';
  
  // Configuración actual (cambiar según el entorno)
  static String get baseUrl {
    // En desarrollo usar localhost para web
    // Para emulador Android cambiar a: 'http://10.0.2.2:3001'
    // Para dispositivo físico cambiar a: 'http://[TU_IP]:3001'
    return _localBaseUrl;
  }
  
  // Endpoints específicos
  static String get healthEndpoint => '$baseUrl/api/health';
  static String get loginEndpoint => '$baseUrl/api/auth/login';
  static String get registerEndpoint => '$baseUrl/api/auth/register';
  static String get profileEndpoint => '$baseUrl/api/auth/profile';
  
  // Configuración de timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Headers por defecto
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
