import 'dart:ui';
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/email_verification_screen.dart';

class RegisterPsychologistScreen extends StatefulWidget {
  const RegisterPsychologistScreen({super.key});

  @override
  _RegisterPsychologistScreenState createState() => _RegisterPsychologistScreenState();
}

class _RegisterPsychologistScreenState extends State<RegisterPsychologistScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  int currentStep = 1;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _birthDate;

  String? validateBirthDate(String? value) {
    if (_birthDate == null) {
      return 'Por favor selecciona tu fecha de nacimiento';
    }
    return null;
  }

  String? validateConfirmPassword(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 205, 223, 222),
                  Color.fromARGB(255, 147, 213, 207),
                ],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getHorizontalPadding(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // AppBar
                            SizedBox(
                              height: kToolbarHeight * 0.8,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.black54,
                                    ),
                                    iconSize: ResponsiveUtils.getIconSize(context, 22),
                                    onPressed: () {
                                      if (currentStep > 1) {
                                        setState(() => currentStep--);
                                      } else {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.02),

                            // Header
                            _buildStepHeader(context, constraints),

                            SizedBox(height: constraints.maxHeight * 0.03),

                            // Formulario
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getBorderRadius(context, 32),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 20 : 28),
                                  constraints: BoxConstraints(
                                    maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 255, 255, 255)
                                        .withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getBorderRadius(context, 32),
                                    ),
                                  ),
                                  child: currentStep == 1
                                      ? _buildStep1()
                                      : currentStep == 2
                                          ? _buildStep2()
                                          : _buildStep3(),
                                ),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, BoxConstraints constraints) {
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
        SizedBox(height: constraints.maxHeight * 0.03),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: constraints.maxHeight * 0.02),
        Icon(
          icono,
          size: ResponsiveUtils.getIconSize(context, 60),
          color: AppConstants.accentColor,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Form(
      key: _formKeyStep1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: InputValidators.validateEmail,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
          ),
          SizedBox(height: isMobile ? 18 : 24),

          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: InputValidators.validatePassword,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
            helperText: 'Mínimo 8 caracteres. Incluye mayúsculas, minúsculas y números.',
          ),
          SizedBox(height: isMobile ? 14 : 18),

          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            toggleVisibility: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            validator: validateConfirmPassword,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
          ),

          SizedBox(height: isMobile ? 20 : 28),

          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.getButtonHeight(context),
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
                  borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, 16),
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

  Widget _buildStep2() {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Form(
      key: _formKeyStep2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _professionalIdController,
            hintText: 'No. Cédula Profesional',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: InputValidators.validateProfessionalId,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
          ),
          SizedBox(height: isMobile ? 20 : 28),

          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: () {
                if (_formKeyStep2.currentState?.validate() ?? false) {
                  setState(() => currentStep = 3);
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, 16),
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
    final isMobile = ResponsiveUtils.isMobile(context);

    return Form(
      key: _formKeyStep3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _usernameController,
            hintText: 'Nombre completo',
            icon: Icons.person_outline,
            validator: InputValidators.validateUsername,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
          ),
          SizedBox(height: isMobile ? 18 : 24),

          CustomTextField(
            controller: _phoneController,
            hintText: 'Número de teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: InputValidators.validatePhoneNumber,
            filled: true,
            fillColor: const Color(0xFF82c4c3),
            borderRadius: 14,
            placeholderColor: Colors.white,
          ),
          SizedBox(height: isMobile ? 18 : 24),

          GestureDetector(
            onTap: () async {
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
                setState(() => _birthDate = pickedDate);
              }
            },
            child: AbsorbPointer(
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
                fillColor: const Color(0xFF82c4c3),
                borderRadius: 14,
                placeholderColor: Colors.white,
                readOnly: true,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 24 : 32),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Error desconocido'),
                    backgroundColor: AppConstants.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
              if (state.status == AuthStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro exitoso! Por favor verifica tu correo.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                if (!context.mounted) return;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => EmailVerificationScreen(
                      userEmail: _emailController.text,
                      userRole: 'psychologist',
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.getButtonHeight(context),
                child: ElevatedButton(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : () {
                          if (_formKeyStep3.currentState?.validate() ?? false) {
                            context.read<AuthBloc>().add(
                              AuthRegisterPsychologistRequested(
                                username: _usernameController.text.trim(),
                                email: _emailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                professionalLicense: _professionalIdController.text.trim(),
                                password: _passwordController.text.trim(),
                                dateOfBirth: _birthDate!,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: state.status == AuthStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 16),
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
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _professionalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}