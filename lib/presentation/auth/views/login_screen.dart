// lib/presentation/auth/views/login_screen.dart

import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/role_selection_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;


  Widget _buildORDivider() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1, color: Colors.grey.shade400)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'O',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(child: Divider(thickness: 1, color: Colors.grey.shade400)),
      ],
    );
  }
  //Fondo degradado
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 255, 255, 255), // Teal claro
                  Color.fromARGB(255, 205, 223, 222), // Teal medio
                  Color(0xFF80CBC4), // Teal más fuerte
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    // Logo con ajuste
                    SizedBox(
                      width: 300,
                      height: 120,
                      child: Image.asset(AppConstants.logoAuroraPath),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bienvenido!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Formulario
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255, // Alpha
                              255, // Red
                              255, // Green
                              255, // Blue
                            ).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  hintText: 'Email',
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: InputValidators.validateEmail,
                                  filled: true,
                                  fillColor: Color(0xFF82c4c3),
                                  borderRadius: 16,
                                  placeholderColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  hintText: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  toggleVisibility: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: InputValidators.validatePassword,
                                  filled: true,
                                  fillColor: Color(0xFF82c4c3),
                                  borderRadius: 16,
                                  placeholderColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Acción para recuperar contraseña - podrías navegar a una pantalla de recuperación
                                    },
                                    child: Text(
                                      '¿Olvidaste tu contraseña? Recuperar contraseña',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color.fromARGB(
                                          255,
                                          2,
                                          2,
                                          2,
                                        ).withOpacity(0.9),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                BlocConsumer<AuthBloc, AuthState>(
                                  listener: (context, state) {
                                    if (state.status == AuthStatus.error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            state.errorMessage ?? 'Error desconocido',
                                          ),
                                          backgroundColor: AppConstants.errorColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.all(16),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            state.status == AuthStatus.loading
                                                ? null // Deshabilita el botón mientras carga
                                                : () {
                                                    if (_formKey.currentState?.validate() ?? false) {
                                                      context.read<AuthBloc>().add(
                                                            AuthSignInRequested( 
                                                              email: _emailController.text,
                                                              password: _passwordController.text,
                                                            ),
                                                          );
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: const [
                                                              Icon(
                                                                Icons.warning_amber_rounded,
                                                                color: Colors.white,
                                                              ),
                                                              SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Por favor completa todos los campos correctamente.', // Mensaje más específico
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor: Color.fromARGB(221, 255, 10, 10),
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          margin: EdgeInsets.all(16),
                                                          duration: Duration(seconds: 3),
                                                        ),
                                                      );
                                                    }
                                                  },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 4,
                                          backgroundColor: null, 
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          padding: const EdgeInsets.all(0),
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF82c4c3),
                                                Color(0xFF5ca0ac),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: Center(
                                            child: state.status == AuthStatus.loading
                                                ? const CircularProgressIndicator(color: Colors.white)
                                                : const Text(
                                                    'Iniciar Sesión',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                _buildORDivider(),

                                const SizedBox(height: 20),
                               // --- BOTÓN GOOGLE ---
                               
                                BlocConsumer<AuthBloc, AuthState>(
                                  listener: (context, state) {
                                
                                  },
                                  builder: (context, state) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        icon: Image.asset(
                                          'assets/images/google-logo-icon.png',
                                          height: 24,
                                          width: 24,
                                        ),
                                        label: const Text(
                                          'Continuar con Google',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                        // Ahora 'state' está disponible aquí
                                        onPressed: state.status == AuthStatus.loading
                                            ? null // Deshabilita el botón mientras carga
                                            : () {
                                                
                                                context.read<AuthBloc>().add(AuthSignInWithGoogleRequested());
                                              },
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Enlace para crear cuenta
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => RoleSelectionScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '¿No tienes una cuenta? ',
                                        ),
                                        TextSpan(
                                          text: 'Crear Cuenta',
                                          style: TextStyle(
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
                    const SizedBox(height: 30),
                    const SizedBox(height: 60),
                    const Text(
                      'AURORA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black26,
                        letterSpacing: 2.0,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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