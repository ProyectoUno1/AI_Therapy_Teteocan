import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as auth_provider;

class RegisterPsychologistScreen extends StatefulWidget {
  @override
  _RegisterPsychologistScreenState createState() =>
      _RegisterPsychologistScreenState();
}

class _RegisterPsychologistScreenState
    extends State<RegisterPsychologistScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionalIdController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
            _buildTextField(
              _professionalIdController,
              'No. Cédula Profesional',
              Icons.credit_card,
              keyboardType: TextInputType.number,
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
                  _handleRegisterPsychologist();
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

  // Lógica de registro para psicólogo
  void _handleRegisterPsychologist() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String professionalId = _professionalIdController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        professionalId.isEmpty ||
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

    // Validación simple de número de teléfono
    if (!RegExp(r'^[0-9]+$').hasMatch(phone) || phone.length < 7) {
      _showSnackBar(
        'Por favor ingresa un número de teléfono válido',
        Colors.red,
      );
      return;
    }

    // Validación de formato de cédula profesional (ejemplo: solo números, 7-10 dígitos)
    if (!RegExp(r'^[0-9]{7,10}$').hasMatch(professionalId)) {
      _showSnackBar(
        'La cédula profesional debe contener solo números y tener entre 7 y 10 dígitos',
        Colors.red,
      );
      return;
    }

    // Usar AuthProvider para el registro
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    // Aquí puedes decidir cómo pasar los datos adicionales (rol, cédula, etc.)
    // Una opción es tener un método de registro más específico en tu AuthProvider/AuthService
    // Por ahora, usaremos el registro genérico y mostraremos un mensaje.
    // TODO: Adaptar el método `register` en AuthProvider para aceptar rol y datos adicionales.

    bool success = await authProvider.register(email, password, username);

    if (success) {
      // Aquí también deberías enviar los datos adicionales (cédula, teléfono, rol)
      // a tu backend usando un método en tu AuthService.
      print(
        'Registro exitoso. TODO: Enviar datos adicionales a backend: Cédula: $professionalId, Rol: psicologo',
      );
      _showSnackBar('Registro de psicólogo exitoso!', Colors.green);
      // La navegación es manejada por AuthWrapper, por lo que no se necesita un Navigator.push aquí.
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Error al registrar psicólogo',
        Colors.red,
      );
    }
  }

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
    _professionalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
