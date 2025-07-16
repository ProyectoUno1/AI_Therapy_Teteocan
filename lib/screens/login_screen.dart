import 'package:flutter/material.dart';

// La clase LoginScreen y su estado se mueven a este archivo.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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

                    SizedBox(height: 20),

                    // Formulario de login
                    _buildLoginForm(),

                    SizedBox(height: 30),

                    // Enlace para crear cuenta
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
    // Asegúrate de que la ruta de la imagen sea correcta
    // Si 'assets/images/LogoAurora.png' no funciona, verifica tu pubspec.yaml
    // y la ubicación real del archivo.
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 32),

        // Botón de iniciar sesión
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountLink() {
    return RichText(
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
    );
  }

  Widget _buildBottomLogo() {
    return Text(
      'AURORA',
      style: TextStyle(fontSize: 10, color: Colors.black26, letterSpacing: 2.0),
    );
  }

  void _handleLogin() {
    // Aquí puedes agregar la lógica de autenticación
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simular proceso de login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando sesión...'),
        backgroundColor: Color(0xFF4DB6AC),
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
