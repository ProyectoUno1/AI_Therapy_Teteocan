import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/patient/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/screens/psychologist/psychologist_home_screen.dart';
// Para redirigir después del registro
// Importa Firebase Auth (descomenta cuando tengas Firebase configurado)
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert'; // Para jsonEncode
// import 'package:http/http.dart' as http; // Para enviar datos al backend

class RegisterPatientScreen extends StatefulWidget {
  @override
  _RegisterPatientScreenState createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () {
            Navigator.of(
              context,
            ).pop(); // Regresar a la pantalla anterior (Selección de rol)
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Barra de progreso y texto "Segundo paso"
            _buildProgressBar(context, 'Segundo paso'),
            SizedBox(height: 40),

            // Título "Crear cuenta" y icono
            Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 20),
            Icon(
              Icons.person_outline, // Icono de usuario
              size: 80,
              color: accentColor,
            ),
            SizedBox(height: 40),

            // Campos de formulario
            _buildTextField(
              _usernameController,
              'Username',
              Icons.person_outline,
            ),
            SizedBox(height: 16),
            _buildTextField(
              _emailController,
              'Email',
              Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            _buildTextField(
              _phoneController,
              'Número de teléfono',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              _passwordController,
              'Password',
              _obscurePassword,
              () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              _confirmPasswordController,
              'Confirmar password',
              _obscureConfirmPassword,
              () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            SizedBox(height: 40),

            // Botón "Crear cuenta"
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  _handleRegisterPatient();
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
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            SizedBox(height: 50), // Espacio adicional al final
          ],
        ),
      ),
    );
  }

  // Widget para la barra de progreso (copiado de RoleSelectionScreen)
  Widget _buildProgressBar(BuildContext context, String stepText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2, // Parte completada (ambos pasos)
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              flex: 0, // No hay parte por completar en este paso final
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            stepText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // Widget genérico para campos de texto
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: lightAccentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          prefixIcon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Widget para campos de contraseña con toggle de visibilidad
  Widget _buildPasswordField(
    TextEditingController controller,
    String hintText,
    bool obscureText,
    VoidCallback toggleVisibility,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: lightAccentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: toggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Lógica de registro para paciente
  void _handleRegisterPatient() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.red);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('Por favor ingresa un email válido', Colors.red);
      return;
    }

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

    // Validación simple de número de teléfono (puedes mejorar con regex más complejos)
    if (!RegExp(r'^[0-9]+$').hasMatch(phone) || phone.length < 7) {
      _showSnackBar(
        'Por favor ingresa un número de teléfono válido',
        Colors.red,
      );
      return;
    }

    // Aquí iría la lógica de registro con Firebase Authentication
    /*
    try {
      _showSnackBar('Registrando paciente...', accentColor);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(username);

      // *** PASO CRÍTICO: ENVIAR DATOS AL BACKEND CON ROL ***
      // Envía el UID de Firebase y otros datos relevantes a tu backend Node.js
      // Incluye el rol 'paciente'
      // await _sendUserDataToBackend(userCredential.user!.uid, username, email, phone, 'paciente');

      _showSnackBar('Registro de paciente exitoso!', Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
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

    // Simulación de registro
    _showSnackBar('Simulando registro de paciente...', accentColor);
    print(
      'Paciente: Username: $username, Email: $email, Phone: $phone, Password: $password',
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PsychologistHomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // TODO: Implementar _sendUserDataToBackend para enviar datos a Node.js/PostgreSQL
  /*
  Future<void> _sendUserDataToBackend(String firebaseUid, String username, String email, String phone, String role, {String? professionalId}) async {
    final response = await http.post(
      Uri.parse('http://YOUR_NODEJS_BACKEND_IP_OR_DOMAIN:PORT/api/register'), // Reemplaza con tu URL
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'firebaseUid': firebaseUid,
        'username': username,
        'email': email,
        'phone': phone,
        'role': role,
        'professionalId': professionalId, // Será nulo para pacientes
      }),
    );

    if (response.statusCode == 201) {
      print('Datos del usuario ($role) guardados en PostgreSQL.');
    } else {
      print('Error al guardar datos en PostgreSQL: ${response.body}');
      _showSnackBar('Error al guardar datos en el servidor.', Colors.red);
    }
  }
  */

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
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
