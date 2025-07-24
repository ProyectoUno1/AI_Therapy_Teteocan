import 'dart:ui'; // Para ImageFilter blur
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';

// Firebase y Google Sign-In
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  int currentStep = 1;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  DateTime? _birthDate;
  final TextEditingController _birthDateController = TextEditingController();

  UserCredential? _userCredential;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Función para mostrar selector de fecha
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  String? validateBirthDate(String? value) {
    if (_birthDate == null) {
      return 'Por favor selecciona tu fecha de nacimiento';
    }
    return null;
  }

  //validar password
  String? validateConfirmPassword(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null; // válido
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      setState(() {
        _userCredential = userCredential;
        _emailController.text = userCredential.user?.email ?? '';
        if (currentStep == 1) {
          currentStep = 2;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google sign-in exitoso, completa el resto del formulario.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
      );
    }
  }

  void _signOutGoogle() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    setState(() {
      _userCredential = null;
      _emailController.clear();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // blanco base
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Manchas circulares decorativas
          Align(
            alignment: Alignment.bottomLeft,
            child: Transform.translate(
              offset: const Offset(-100, 70),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color.fromARGB(136, 59, 113, 111),
                      const Color.fromARGB(64, 223, 253, 253),
                    ],
                    radius: 0.6,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.translate(
              offset: const Offset(100, 20),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color.fromARGB(197, 92, 160, 172),
                      const Color.fromARGB(0, 142, 236, 225),
                    ],
                    radius: 0.6,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        if (currentStep > 1) {
                          setState(() => currentStep--);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),

                  // Título e ícono según paso actual
                  Builder(
                    builder: (context) {
                      String titulo = '';
                      IconData icono = Icons.info_outline;

                      switch (currentStep) {
                        case 1:
                          titulo = 'Ingresa tu correo y contraseña';
                          icono = Icons.mail_outline;
                          break;
                        case 2:
                          titulo = 'Completa tu perfil';
                          icono = Icons.person_outline;
                          break;
                      }

                      return Column(
                        children: [
                          ProgressBarWidget(
                            stepText: 'Paso $currentStep de 2',
                            currentStep: currentStep,
                            totalSteps: 2,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Icon(
                            icono,
                            size: 80,
                            color: AppConstants.accentColor,
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),

                  // Formulario dentro de contenedor con blur + fondo con opacidad y bordes redondeados
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82c4c3).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: currentStep == 1 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        children: [
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: InputValidators.validateEmail,
            filled: true,
            fillColor: Colors.white,
            borderRadius: 16,
            placeholderColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            toggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: InputValidators.validatePassword,
            filled: true,
            fillColor: Colors.white,
            borderRadius: 16,
            placeholderColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            toggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            validator: validateConfirmPassword,
            filled: true,
            fillColor: Colors.white,
            borderRadius: 16,
            placeholderColor: Colors.grey.shade600,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_formKeyStep1.currentState?.validate() ?? false) {
                  setState(() => currentStep = 2);
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF82c4c3), Color(0xFF5ca0ac)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'Continuar',
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
          ),
          const SizedBox(height: 24),
          _buildORDivider(),
          const SizedBox(height: 24),
          SizedBox(
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
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              onPressed: _signInWithGoogle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        children: [
          CustomTextField(
            controller: _usernameController,
            hintText: 'Username',
            icon: Icons.person_outline,
            validator: InputValidators.validateUsername,
            filled: true,
            fillColor: Colors.white,
            borderRadius: 16,
            placeholderColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _phoneController,
            hintText: 'Número de teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: InputValidators.validatePhoneNumber,
            filled: true,
            fillColor: Colors.white,
            borderRadius: 16,
            placeholderColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 32),

          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final firstDate = DateTime(
                now.year - 120,
              ); // límite mínimo: hace 120 años
              final lastDate = now; // límite máximo: hoy

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime(now.year - 18),
                firstDate: firstDate,
                lastDate: lastDate,
                helpText: 'Selecciona tu fecha de nacimiento',
              );

              if (pickedDate != null) {
                setState(() {
                  _birthDate = pickedDate;
                });
              }
            },
            child: AbsorbPointer(
              // Para que el TextField no reciba foco y no permita escribir directamente
              child: CustomTextField(
                controller: TextEditingController(
                  text: _birthDate != null
                      ? '${_birthDate!.year.toString().padLeft(4, '0')}-'
                            '${_birthDate!.month.toString().padLeft(2, '0')}-'
                            '${_birthDate!.day.toString().padLeft(2, '0')}'
                      : '',
                ),
                hintText: 'Fecha de nacimiento (YYYY-MM-DD)',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (_birthDate == null) {
                    return 'Por favor selecciona tu fecha de nacimiento';
                  }
                  return null;
                },
                filled: true,
                fillColor: Colors.white,
                borderRadius: 16,
                placeholderColor: Colors.grey.shade600,
                readOnly: true,
                onTap: () async {
                  // Repetimos para que también funcione si tocan el TextField
                  final now = DateTime.now();
                  final firstDate = DateTime(now.year - 120);
                  final lastDate = now;

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(now.year - 18),
                    firstDate: firstDate,
                    lastDate: lastDate,
                    helpText: 'Selecciona tu fecha de nacimiento',
                  );

                  if (pickedDate != null) {
                    setState(() {
                      _birthDate = pickedDate;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Error desconocido'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
              if (state.status == AuthStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro exitoso'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : () {
                          if (_formKeyStep2.currentState?.validate() ?? false) {
                            context.read<AuthBloc>().add(
                              AuthRegisterPatientRequested(
                                username: _usernameController.text.trim(),
                                email: _emailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                password: _passwordController.text.trim(),
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
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF82c4c3), Color(0xFF5ca0ac)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: state.status == AuthStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Crear cuenta',
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}
