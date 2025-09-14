import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Configura GoogleSignIn para la web o para otras plataformas
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: kIsWeb
        ? '923310808660-u1lvndctmelhjggu81qem3la55monf1l.apps.googleusercontent.com' // Solo para web
        : null, // Android usa automáticamente la configuración de Google Cloud Console
  );

  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Inicio de sesión cancelado.');
        setState(() => _isLoading = false);
        return;
      }

      final String userEmail = googleUser.email;
      const List<String> allowedDomains = ['uct.cl', 'alu.uct.cl'];
      bool isDomainAllowed =
          allowedDomains.any((domain) => userEmail.endsWith('@$domain'));

      if (!isDomainAllowed) {
        print('Dominio de correo no permitido: $userEmail');
        await _googleSignIn.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Solo se permiten correos de @uct.cl o @alu.uct.cl.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // --- Obtener autenticación ---
      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('ID Token: $idToken');
      print('Access Token: $accessToken');

      // --- CASO DE ÉXITO ---
      print('✅ Acceso permitido: ${googleUser.displayName}');

      // Usar accessToken si idToken es null (solución para web)
      final String tokenToUse = idToken ?? accessToken ?? '';

      if (tokenToUse.isNotEmpty) {
        final authService = AuthService();
        await authService.saveToken(tokenToUse);

        if (mounted) {
          context.go('/home');
        }
      } else {
        throw Exception('No se pudo obtener ningún token de autenticación');
      }
    } catch (error) {
      print('⚠️ Error al iniciar sesión: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Mantener login como invitado
  void _loginAsGuest() async {
    final authService = AuthService();
    await authService.saveToken('guest_user_token');
    if (mounted) {
      context.go('/home');
    }
  }

  // Método para el login del administrador
  void _loginAsAdmin() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.saveToken('admin_user_token');

      if (mounted) {
        context.go('/admin');
      }
    } catch (error) {
      print('⚠️ Error al iniciar sesión como admin: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error al iniciar sesión como admin: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.azulClaro,
              AppColors.azulPrimario,
              AppColors.azulOscuro,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.store,
                        size: 80,
                        color: AppColors.azulPrimario,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'MicroMarket',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulPrimario,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.azulPrimario),
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Image.network(
                                  'http://pngimg.com/uploads/google/google_PNG19635.png',
                                  height: 24.0,
                                  frameBuilder: (context, child, frame,
                                      wasSynchronouslyLoaded) {
                                    if (wasSynchronouslyLoaded) return child;
                                    return AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      child: child,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.login,
                                      color: AppColors.azulPrimario,
                                    );
                                  },
                                ),
                          label: Text(
                            _isLoading
                                ? 'INICIANDO SESIÓN...'
                                : 'INICIAR SESIÓN CON GOOGLE',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textoOscuro,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blanco,
                            foregroundColor: AppColors.textoOscuro,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _loginAsGuest,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.amarilloPrimario),
                            foregroundColor: AppColors.amarilloPrimario,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('ENTRAR COMO INVITADO'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginAsAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ADMINISTRADOR',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Inicia sesión para una experiencia completa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
