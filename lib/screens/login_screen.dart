import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

// Clipper para el efecto de onda como en startup
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(
        0,
        size.height * 0.70, // Comenzar el curveado aún más arriba
      );

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.80, // Curva más pronunciada y más arriba
      size.width * 0.5,
      size.height * 0.70,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.60, // Curva mucho más elevada
      size.width,
      size.height * 0.75,
    );

    path
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

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Configura GoogleSignIn para la web o para otras plataformas
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: kIsWeb
        ? '923310808660-u1lvndctmelhjggu81qem3la55monf1l.apps.googleusercontent.com' // Solo para web
        : null, // Android usa automáticamente la configuración de Google Cloud Console
  );

  bool _isLoading = false;
  bool _rememberMe = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Animación de abajo hacia arriba (Y positivo a Y cero)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Comienza desde abajo (Y=1)
      end: Offset.zero,              // Termina en la posición normal (Y=0)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart, // Curva más suave para efecto de "empuje"
    ));
    
    // Iniciar animación directamente al mostrar la pantalla
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // Login con email y password (nuevo método)
  void _loginWithEmailPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final response = await authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.ok && mounted) {
        context.go('/home');
      }
    } catch (error) {
      print('⚠️ Error al iniciar sesión: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
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

      if (idToken != null) {
        // Usar la nueva API
        final authService = AuthService();
        final response = await authService.loginWithGoogle(
          idToken: idToken,
          email: googleUser.email,
          name: googleUser.displayName ?? '',
          googleId: googleUser.id,
          avatarUrl: googleUser.photoUrl,
        );

        if (response.ok && mounted) {
          print('✅ Login con Google exitoso: ${response.user?.name}');
          context.go('/home');
        }
      } else {
        throw Exception('No se pudo obtener token de Google');
      }
    } catch (error) {
      print('⚠️ Error al iniciar sesión con Google: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
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
            content: Text('Error al iniciar sesión como admin: ${error.toString()}'),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFD),
      // Aplicamos animación de deslizamiento y opacidad
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Sección superior con imagen de fondo (35% de la pantalla)
              SizedBox(
                height: screenHeight * 0.35,
                child: ClipPath(
                  clipper: WaveClipper(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Imagen de fondo
                      Image.asset('assets/universidad.jpg', fit: BoxFit.cover),
                      // 2. Capa de color azul con opacidad
                      Container(color: const Color(0xFF005A8A).withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
              
              // Sección inferior con el formulario (65% de la pantalla)
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -30), // Mueve todo el formulario hacia arriba
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título Sign in con línea amarilla
                          Column(
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
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Campo Email
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'demo@email.com',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Campo Password
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                                suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Remember Me y Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.azulPrimario,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      color: AppColors.textoSecundario,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.azulPrimario,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),                          // Botón Login azul
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _loginWithEmailPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrimario,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Botón Continue with Google
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _loginWithGoogle,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Image.network(
                                      'http://pngimg.com/uploads/google/google_PNG19635.png',
                                      height: 20.0,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.login,
                                          color: Colors.grey,
                                          size: 20,
                                        );
                                      },
                                    ),
                              label: Text(
                                _isLoading ? 'Signing in...' : 'Continue with Google',
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
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Botones Invitado y Admin
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _loginAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.amarilloPrimario),
                                    foregroundColor: AppColors.amarilloPrimario,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text(
                                    'Invitado',
                                    style: TextStyle(fontSize: 12),
                                  ),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Don't have an Account? Sign up
                          Center(
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an Account ? ",
                                style: TextStyle(
                                  color: AppColors.textoSecundario,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: AppColors.azulPrimario,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
