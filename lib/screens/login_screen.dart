import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_therapy_teteocan/screens/register_screen.dart';
import '../providers/auth_provider.dart' as auth_provider;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Instancia de FirebaseAuth (descomenta cuando tengas Firebase configurado)
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Evitar que el teclado se desplace
      body: Stack(
        children: [
          // Elementos de fondo curvos
          _buildBackgroundShapes(),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 90),

                    // Logo
                    _buildLogo(),

                    SizedBox(height: 20),

                    // Texto de bienvenida
                    _buildWelcomeText(),

                    SizedBox(height: 40),

                    // Formulario de login (ahora incluye botón de Google)
                    _buildLoginForm(),

                    SizedBox(height: 30),

                    // Enlace para crear cuenta (navega a RegisterScreen)
                    _buildCreateAccountLink(),

                    SizedBox(height: 60),

                    // Logo inferior
                    _buildBottomLogo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de construcción de widgets auxiliares
  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // Forma curva superior derecha
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Color(0xFF5CA0AC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(125)),
            ),
          ),
        ),

        // Forma curva inferior izquierda
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF3B716F),
              borderRadius: BorderRadius.only(topRight: Radius.circular(160)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 400,
      height: 150,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/LogoAurora.png'),
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      'Bienvenido!',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Campo de email
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFF80CBC4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.mail_outline, color: Colors.white),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Campo de contraseña
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFF80CBC4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        SizedBox(height: 8),

        // Enlace de recuperar contraseña
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.black54),
                children: [
                  TextSpan(text: '¿Olvidaste tu contraseña? '),
                  TextSpan(
                    text: 'Recuperar contraseña',
                    style: TextStyle(
                      color: Color(0xFF4DB6AC),
                      decoration: TextDecoration.underline,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 32),

        // Botón de iniciar sesión (Email/Contraseña)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              _handleLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Separador "o"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.black26)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text('o', style: TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Divider(color: Colors.black26)),
          ],
        ),

        SizedBox(height: 20),

        // Botón para iniciar sesión con Google
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              _handleGoogleSignIn();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF4DB6AC),
              side: BorderSide(color: Color(0xFF4DB6AC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/2048px-Google_%22G%22_logo.svg.png', // Logo de Google
              height: 24.0,
              width: 24.0,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.g_mobiledata,
                color: Color(0xFF4DB6AC),
              ), // Fallback icon
            ),
            label: Text(
              'Iniciar Sesión con Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountLink() {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de registro
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterScreen()),
        );
      },
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.black54),
          children: [
            TextSpan(text: '¿No tienes una cuenta? '),
            TextSpan(
              text: 'Crear Cuenta',
              style: TextStyle(
                color: Color(0xFF4DB6AC),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLogo() {
    return Text(
      'AURORA',
      style: TextStyle(fontSize: 10, color: Colors.black26, letterSpacing: 2.0),
    );
  }

  // Lógica de inicio de sesión con Email y Contraseña
  void _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.red);
      return;
    }

    // Validación de formato de email
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('Por favor ingresa un email válido', Colors.red);
      return;
    }

    // Validación de longitud de contraseña (ejemplo: mínimo 6 caracteres)
    if (password.length < 6) {
      _showSnackBar(
        'La contraseña debe tener al menos 6 caracteres',
        Colors.red,
      );
      return;
    }

    // Usar AuthProvider para el login
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    
    bool success = await authProvider.signInWithEmailAndPassword(email, password);
    
    if (success) {
      _showSnackBar('Inicio de sesión exitoso!', Colors.green);
      // La navegación se maneja automáticamente por el AuthWrapper
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Error al iniciar sesión',
        Colors.red,
      );
    }
  }

  // Lógica de inicio de sesión con Google
  void _handleGoogleSignIn() async {
    // Usar AuthProvider para el login con Google
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    
    bool success = await authProvider.signInWithGoogle();
    
    if (success) {
      _showSnackBar('Inicio de sesión con Google exitoso!', Colors.green);
      // La navegación se maneja automáticamente por el AuthWrapper
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Error al iniciar sesión con Google',
        Colors.red,
      );
    }
  }

  // Método auxiliar para mostrar SnackBar
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
