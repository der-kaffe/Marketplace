import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Configura GoogleSignIn para la web o para otras plataformas
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '923310808660-u1lvndctmelhjggu81qem3la55monf1l.apps.googleusercontent.com' // ID para web
        : '923310808660-0e6dchkc7di29grqa0jrcfot2c8mi5c7.apps.googleusercontent.com', // ID para Android
    scopes: ['email'],
  );

  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Inicio de sesión cancelado.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final String userEmail = googleUser.email;
      const List<String> allowedDomains = ['uct.cl', 'alu.uct.cl'];

      bool isDomainAllowed =
          allowedDomains.any((domain) => userEmail.endsWith('@$domain'));

      if (!isDomainAllowed) {
        print('Dominio de correo no permitido: $userEmail');
        await _googleSignIn.signOut();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo se permiten correos de @uct.cl o @alu.uct.cl.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Acceso permitido: ${googleUser.displayName}');
      // ignore: use_build_context_synchronously
      context.go('/home');
    } catch (error) {
      print('Error al iniciar sesión: $error');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loginAsGuest() {
    context.go('/home');
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
                          onPressed: _isLoading
                              ? null
                              : () {
                                  context.go('/admin');
                                },
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
