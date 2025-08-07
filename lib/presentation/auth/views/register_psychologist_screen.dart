import 'dart:ui'; // Para aplicar desenfoque con ImageFilter (efecto blur)
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart'; // Barra de progreso personalizada
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Gestión de estados con BLoC
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart'; // Colores y constantes generales
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart'; // Colores y constantes generales
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart'; // BLoC para autenticación
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart'; // Campo de texto personalizado
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';

class RegisterPsychologistScreen extends StatefulWidget {
  @override
  _RegisterPsychologistScreenState createState() =>
      _RegisterPsychologistScreenState();
}

class _RegisterPsychologistScreenState
    extends State<RegisterPsychologistScreen> {
  // Claves para validar cada paso del formulario
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  int currentStep = 1;

  // Controladores de campos
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

  // Muestra el selector de fecha de nacimiento
  DateTime? _birthDate;

  final TextEditingController _birthDateController = TextEditingController();

  // Valida que se haya elegido una fecha
  String? validateBirthDate(String? value) {
    if (_birthDate == null) {
      return 'Por favor selecciona tu fecha de nacimiento';
    }
    return null;
  }

  // Verifica que la contraseña coincida

  String? validateConfirmPassword(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null; // válido
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos backgroundColor para que el Stack maneje el fondo
      body: Stack(
        children: [
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
                  Color.fromARGB(255, 147, 213, 207), // Teal más fuerte
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón atrás y navegación por pasos
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
                          setState(() {
                            currentStep--;
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),

                  // Título e ícono según el paso actual
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
                          titulo = 'Datos profesionales';
                          icono = Icons.credit_card;
                          break;
                        case 3:
                          titulo = 'Completa tus datos personales';
                          icono = Icons.person_outline;
                          break;
                      }

                      return Column(
                        children: [
                          ProgressBarWidget(
                            stepText: 'Paso $currentStep de 3',
                            currentStep: currentStep,
                            totalSteps: 3,
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

                  // Contenedor con blur y contenido dinámico según el paso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: currentStep == 1
                            ? _buildStep1()
                            : currentStep == 2
                            ? _buildStep2()
                            : _buildStep3(),
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

  //Primer paso de formulario
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1, // Llave para validar este formulario
      child: Column(
        children: [
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: InputValidators.validateEmail, // Validación email
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: Colors.white,
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            toggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator:
                InputValidators.validatePassword, // Validación contraseña
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: const Color.fromARGB(255, 255, 255, 255),
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
            validator:
                validateConfirmPassword, // Valida que coincida con password
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: const Color.fromARGB(255, 255, 255, 255),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Si formulario válido, avanzar al siguiente paso
                if (_formKeyStep1.currentState?.validate() ?? false) {
                  setState(() {
                    currentStep = 2;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.all(0),
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2, // Llave para validar segundo formulario
      child: Column(
        children: [
          CustomTextField(
            controller: _professionalIdController,
            hintText: 'No. Cédula Profesional',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: InputValidators.validateProfessionalId,
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: Colors.white,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_formKeyStep2.currentState?.validate() ?? false) {
                  setState(() {
                    currentStep = 3;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.all(0),
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
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeyStep3, // Llave para validar último formulario
      child: Column(
        children: [
          CustomTextField(
            controller: _usernameController,
            hintText: 'Username',
            icon: Icons.person_outline,
            validator: InputValidators.validateUsername, // Validar username
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: Colors.white,
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _phoneController,
            hintText: 'Número de teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: InputValidators.validatePhoneNumber, // Validar teléfono
            filled: true,
            fillColor: Color(0xFF82c4c3),
            borderRadius: 16,
            placeholderColor: Colors.white,
          ),
          const SizedBox(height: 32),

          // Selector fecha de nacimiento con picker
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
                fillColor: Color(0xFF82c4c3),
                borderRadius: 16,
                placeholderColor: Colors.white,
                readOnly: true,
                onTap: () async {
                  // Igual que el GestureDetector para mostrar el date picker
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

          // Botón para crear cuenta con estado cargando y manejo de errores con Bloc
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
                    content: Text(
                      'Registro exitoso! Ahora completa tu perfil profesional',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                if (!context.mounted) return;

                // Redirige a la configuración profesional
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ProfessionalInfoSetupScreen(),
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
                          // Dispara evento Bloc para registrar psicólogo
                          if (_formKeyStep3.currentState?.validate() ?? false) {
                            context.read<AuthBloc>().add(
                              AuthRegisterPsychologistRequested(
                                username: _usernameController.text.trim(),
                                email: _emailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                professionalLicense: _professionalIdController
                                    .text
                                    .trim(),
                                password: _passwordController.text.trim(),
                                dateOfBirth: _birthDate!,
                              ),
                            );
                          }
                        },
                  // Estilo del botón Crear cuenta
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: EdgeInsets.all(0),
                  ),
                  // Contenedor para el botón
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
                      // Si está cargando muestra spinner, si no el texto "Crear cuenta"
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

  //libera los controladores al cerrar el widget
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _professionalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}
