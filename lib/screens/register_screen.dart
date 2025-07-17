import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/login_screen.dart';
// Importa Firebase Auth y Google Sign-In (descomenta y añade a pubspec.yaml si aún no lo has hecho)
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'dart:convert'; // Para jsonEncode
// import 'package:http/http.dart' as http; // Para enviar datos al backend

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Instancia de FirebaseAuth (descomenta cuando tengas Firebase configurado)
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Evita que el fondo se mueva cuando el teclado aparece
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Elementos de fondo curvos (igual que en LoginScreen)
          _buildBackgroundShapes(),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 90),

                    // Logo (igual que en LoginScreen)
                    _buildLogo(),

                    SizedBox(height: 20),

                    // Texto de bienvenida/registro
                    _buildWelcomeText(),

                    SizedBox(height: 40),

                    // Formulario de registro
                    _buildRegisterForm(),

                    SizedBox(height: 30),

                    // Enlace para iniciar sesión si ya tiene cuenta
                    _buildLoginLink(),

                    SizedBox(height: 60),

                    // Logo inferior (igual que en LoginScreen)
                    _buildBottomLogo(),

                    // Espacio adicional para asegurar que el contenido se desplace por encima de las formas de fondo
                    SizedBox(height: 100), // Aumentado para dar más espacio
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de construcción de widgets auxiliares (copiados de LoginScreen)
  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
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
          image: AssetImage(
            'assets/images/LogoAurora.png',
          ), // Asegúrate de tener esta imagen
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      'Crea tu cuenta', // Texto adaptado para registro
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Campo de Nombre (nuevo)
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFF80CBC4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _nameController,
            keyboardType: TextInputType.text,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nombre',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.person_outline, color: Colors.white),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Campo de Email
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

        // Campo de Contraseña
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

        SizedBox(height: 16),

        // Campo de Confirmar Contraseña (nuevo)
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFF80CBC4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Confirmar Contraseña',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
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

        SizedBox(height: 32),

        // Botón de Registrarse
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              _handleRegister();
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
              'Registrarse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

        // Botón para registrarse con Google
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              _handleGoogleSignUp();
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
              'Registrarse con Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      },
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.black54),
          children: [
            TextSpan(text: '¿Ya tienes una cuenta? '),
            TextSpan(
              text: 'Iniciar Sesión',
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

  // Lógica de registro con Email y Contraseña
  void _handleRegister() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
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

    if (password != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }

    // Aquí iría la lógica de registro con Firebase Authentication
    // Ejemplo (descomenta y adapta cuando tengas Firebase configurado):
    /*
    try {
      _showSnackBar('Registrando usuario...', Color(0xFF4DB6AC));
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Actualizar el perfil del usuario con el nombre
      await userCredential.user?.updateDisplayName(name);

      // Enviar datos adicionales al backend de Node.js/Express.js (PostgreSQL)
      // Por ejemplo, puedes enviar el UID de Firebase y el nombre del usuario
      // a tu API REST para guardar en PostgreSQL.
      // await _sendUserDataToBackend(userCredential.user!.uid, name, email);

      _showSnackBar('Registro exitoso!', Colors.green);
      // Navegar a la siguiente pantalla (ej. Home)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'La cuenta ya existe para ese email.';
      } else {
        message = 'Error al registrar: ${e.message}';
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e', Colors.red);
    }
    */

    // Simulación de registro si Firebase no está configurado
    _showSnackBar(
      'Lógica de registro (Email/Contraseña) aquí.',
      Color(0xFF4DB6AC),
    );
    print('Nombre: $name, Email: $email, Contraseña: $password');
  }

  // Lógica de registro con Google
  void _handleGoogleSignUp() async {
    // Aquí iría la lógica de autenticación con Google SignIn de Firebase
    // Necesitarás añadir 'google_sign_in' a tu pubspec.yaml y configurarlo.
    /*
    try {
      _showSnackBar('Iniciando sesión con Google...', Color(0xFF4DB6AC));
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        _showSnackBar('Inicio de sesión con Google cancelado.', Colors.orange);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Enviar datos adicionales al backend de Node.js/Express.js (PostgreSQL)
      // Por ejemplo, puedes enviar el UID de Firebase y el nombre/email del usuario
      // a tu API REST para guardar en PostgreSQL.
      // await _sendUserDataToBackend(userCredential.user!.uid, userCredential.user!.displayName, userCredential.user!.email);

      _showSnackBar('Registro con Google exitoso!', Colors.green);
      // Navegar a la siguiente pantalla (ej. Home)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error al registrar con Google: ${e.message}', Colors.red);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado con Google: $e', Colors.red);
    }
    */

    // Simulación de registro con Google si Firebase no está configurado
    _showSnackBar('Lógica de registro con Google aquí.', Color(0xFF4DB6AC));
  }

  // Método auxiliar para mostrar SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Método para enviar datos al backend (ejemplo)
  /*
  Future<void> _sendUserDataToBackend(String uid, String? name, String? email) async {
    final response = await http.post(
      Uri.parse('YOUR_NODEJS_BACKEND_URL/register'), // Reemplaza con tu URL de backend
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'firebaseUid': uid,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 201) {
      print('Datos del usuario guardados en PostgreSQL.');
    } else {
      print('Error al guardar datos en PostgreSQL: ${response.body}');
      _showSnackBar('Error al guardar datos en el servidor.', Colors.red);
    }
  }
  */

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
