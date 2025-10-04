import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

// Clipper para el efecto de onda
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.80,
        size.width * 0.5,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.60,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: kIsWeb
        ? '923310808660-u1lvndctmelhjggu81qem3la55monf1l.apps.googleusercontent.com'
        : null,
  );

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String userEmail = googleUser.email;
      const allowedDomains = ['uct.cl', 'alu.uct.cl'];
      final isDomainAllowed =
          allowedDomains.any((domain) => userEmail.endsWith('@$domain'));

      if (!isDomainAllowed) {
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

      final googleAuth = await googleUser.authentication;
      final tokenToUse = googleAuth.idToken ?? googleAuth.accessToken ?? '';

      if (tokenToUse.isNotEmpty) {
        final authService = AuthService();
        await authService.saveToken(tokenToUse);
        if (mounted) context.go('/home');
      } else {
        throw Exception('No se pudo obtener un token válido');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginAsGuest() async {
    final authService = AuthService();
    await authService.saveToken('guest_user_token');
    if (mounted) context.go('/home');
  }

  void _loginAsAdmin() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.saveToken('admin_user_token');
      if (mounted) context.go('/admin');
    } catch (error) {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFD),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.35,
                child: ClipPath(
                  clipper: WaveClipper(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/universidad.jpg', fit: BoxFit.cover),
                      Container(
                          color: const Color(0xFF005A8A).withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign in',
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3A3A3A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.amarilloPrimario,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Agregamos espacio antes de los botones
                        const SizedBox(height: 40),

                        // Botón Google
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                    ),
                                  )
                                : Image.network(
                                    'http://pngimg.com/uploads/google/google_PNG19635.png',
                                    height: 20,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Iniciando sesión...'
                                  : 'Continuar con Google',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3A3A3A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF3A3A3A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botones Invitado y Admin
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _loginAsGuest,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.amarilloPrimario),
                                  foregroundColor: AppColors.amarilloPrimario,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Invitado',
                                    style: TextStyle(fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _loginAsAdmin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Admin',
                                    style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
