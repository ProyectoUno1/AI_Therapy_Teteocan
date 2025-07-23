import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/auth/role_selection_screen.dart';
// Importa las nuevas Home Screens específicas por rol
import 'package:ai_therapy_teteocan/screens/patient/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/screens/psychologist/psychologist_home_screen.dart';
// Importa Firebase Auth (descomenta cuando tengas Firebase configurado)
// import 'package:firebase_auth/firebase_auth.dart';
// Importa para jsonDecode y http si vas a usar el backend para _getUserRole
// import 'dart:convert';
// import 'package:http/http.dart' as http;

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

  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

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

                    // Formulario de login
                    _buildLoginForm(),

                    SizedBox(height: 30),

                    // Enlace para crear cuenta (redirige a Selección de rol)
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
              color: accentColor,
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
              color: primaryColor,
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
            color: lightAccentColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
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
            color: lightAccentColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
                children: [
                  TextSpan(text: '¿Olvidaste tu contraseña? '),
                  TextSpan(
                    text: 'Recuperar contraseña',
                    style: TextStyle(
                      color: accentColor,
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

        // Botón de iniciar sesión
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              _handleLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
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
      ],
    );
  }

  Widget _buildCreateAccountLink() {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de selección de rol con animación
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RoleSelectionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0); // Viene desde la derecha
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      },
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
          children: [
            TextSpan(text: '¿No tienes una cuenta? '),
            TextSpan(
              text: 'Crear Cuenta',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
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
      style: TextStyle(
        fontSize: 10,
        color: Colors.black26,
        letterSpacing: 2.0,
        fontFamily: 'Poppins',
      ),
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

    // Aquí iría la lógica de inicio de sesión con Firebase Authentication
    // y la consulta del rol del usuario.
    /*
    try {
      _showSnackBar('Iniciando sesión...', accentColor);
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Una vez autenticado, obtener el UID de Firebase
      String firebaseUid = userCredential.user!.uid;

      // TODO: Consultar tu base de datos (PostgreSQL) o Firebase Firestore/Realtime Database
      // para determinar el rol del usuario (paciente o psicólogo).
      // Esta función _getUserRole debe ser implementada en tu AuthProvider o un servicio.
      String userRole = await _getUserRole(firebaseUid); // Implementa esta función

      if (userRole == 'paciente') {
        _showSnackBar('Bienvenido, paciente!', Colors.green);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PatientHomeScreen()));
      } else if (userRole == 'psicologo') {
        _showSnackBar('Bienvenido, psicólogo!', Colors.green);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PsychologistHomeScreen()));
      } else {
        _showSnackBar('Rol de usuario no reconocido. Contacta a soporte.', Colors.orange);
        await _auth.signOut(); // Cerrar sesión si el rol no es válido
      }

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No se encontró un usuario con ese email.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      } else {
        message = 'Error al iniciar sesión: ${e.message}';
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e', Colors.red);
    }
    */

    // Simulación de inicio de sesión si Firebase no está configurado
    _showSnackBar('Simulando inicio de sesión...', accentColor);
    print('Email: $email, Contraseña: $password');
    // Después de una simulación exitosa, puedes redirigir para probar el flujo
    // Puedes cambiar esto para simular un rol específico durante el desarrollo
    // Por ejemplo, para probar PatientHomeScreen:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PatientHomeScreen()),
    );
    // Para probar PsychologistHomeScreen:
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PsychologistHomeScreen()));
  }

  // TODO: Esta es una función placeholder. DEBES implementarla en tu AuthProvider o un servicio
  // que consulte tu backend (Node.js/PostgreSQL) o Firestore para obtener el rol del usuario.
  // Recibe el Firebase UID del usuario autenticado.
  /*
  Future<String> _getUserRole(String firebaseUid) async {
    // Ejemplo de cómo podrías obtener el rol desde Firestore:
    // import 'package:cloud_firestore/cloud_firestore.dart';
    // DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUid).get();
    // if (userDoc.exists) {
    //   return userDoc.get('role'); // Asume que tienes un campo 'role' en tu documento de usuario
    // }
    // return 'unknown'; // Si el documento no existe o no tiene rol

    // Ejemplo de cómo podrías obtener el rol desde tu backend Node.js:
    // import 'dart:convert';
    // import 'package:http/http.dart' as http;
    // final response = await http.get(
    //   Uri.parse('http://YOUR_NODEJS_BACKEND_IP_OR_DOMAIN:PORT/api/user-role/$firebaseUid'),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   return data['role'];
    // } else {
    //   print('Error al obtener rol del backend: ${response.body}');
    //   return 'unknown';
    // }

    // --- SIMULACIÓN PARA PRUEBAS SIN BACKEND (eliminar en producción) ---
    // Puedes cambiar esto para simular un rol específico durante el desarrollo
    await Future.delayed(Duration(seconds: 1)); // Simula una llamada a la red
    if (firebaseUid.startsWith('patient')) { // Ejemplo: si el UID empieza con 'patient'
      return 'paciente';
    } else if (firebaseUid.startsWith('psychologist')) { // Ejemplo: si el UID empieza con 'psychologist'
      return 'psicologo';
    }
    return 'paciente'; // Por defecto para pruebas si no coincide
    // --- FIN SIMULACIÓN ---
  }
  */

  // Método auxiliar para mostrar SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
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
