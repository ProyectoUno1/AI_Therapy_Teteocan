// lib/presentation/auth/views/login_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/role_selection_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/forgot_password_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/email_verification_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isLandscape = screenWidth > screenHeight;
    
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
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 205, 223, 222),
                  Color(0xFF80CBC4),
                ],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                        ? MediaQuery.of(context).viewInsets.bottom + 20 
                        : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: ResponsiveContainer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Espaciado superior flexible (menor en landscape)
                            if (!isLandscape) 
                              Flexible(flex: 2, child: Container()),
                            if (isLandscape)
                              SizedBox(height: screenHeight * 0.05),
                            
                            // ✅ Logo más pequeño en landscape
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isLandscape ? screenWidth * 0.2 : screenWidth * 0.4,
                                maxHeight: isLandscape ? screenHeight * 0.1 : screenHeight * 0.15,
                              ),
                              child: SizedBox(
                                width: ResponsiveUtils.getLogoWidth(context),
                                height: ResponsiveUtils.getLogoHeight(context),
                                child: Image.asset(
                                  AppConstants.logoAuroraPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isLandscape ? screenHeight * 0.02 : screenHeight * 0.02),
                            
                            // ✅ Título "Bienvenido"
                            FittedBox(
                              child: Text(
                                'Bienvenido!',
                                style: TextStyle(
                                  fontSize: isLandscape 
                                      ? ResponsiveUtils.getFontSize(context, 16)
                                      : ResponsiveUtils.getFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.headlineMedium?.color,
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isLandscape ? screenHeight * 0.02 : screenHeight * 0.03),

                            // ✅ Formulario - Sin limitación de altura máxima en landscape
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? screenWidth * 0.9 : 400,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getBorderRadius(context, 24),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.getHorizontalPadding(context) * 0.6,
                                      vertical: isLandscape 
                                          ? ResponsiveUtils.getVerticalSpacing(context, 12)
                                          : ResponsiveUtils.getVerticalSpacing(context, 16),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtils.getBorderRadius(context, 24),
                                      ),
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ✅ Campo Email
                                          CustomTextField(
                                            controller: _emailController,
                                            hintText: 'Email',
                                            icon: Icons.mail_outline,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: InputValidators.validateEmail,
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.primaryContainer,
                                            borderRadius: 14,
                                            placeholderColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                          
                                          SizedBox(
                                            height: ResponsiveUtils.getVerticalSpacing(context, 12),
                                          ),
                                          
                                          // ✅ Campo Contraseña
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
                                            fillColor: Theme.of(context).colorScheme.primaryContainer,
                                            borderRadius: 14,
                                            placeholderColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                          
                                          SizedBox(height: screenHeight * 0.01),
                                          
                                          // ✅ Link "Olvidaste contraseña"
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        const ForgotPasswordScreen(),
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                      const begin = Offset(1.0, 0.0);
                                                      const end = Offset.zero;
                                                      const curve = Curves.ease;
                                                      var tween = Tween(begin: begin, end: end)
                                                          .chain(CurveTween(curve: curve));
                                                      return SlideTransition(
                                                        position: animation.drive(tween),
                                                        child: child,
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: ResponsiveUtils.getVerticalSpacing(context, 2),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '¿Olvidaste tu contraseña? Recuperar contraseña',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveUtils.getFontSize(context, 11),
                                                      color: const Color.fromARGB(255, 2, 2, 2).withOpacity(0.9),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          SizedBox(height: screenHeight * 0.02),
                                          
                                          // ✅ Botón Iniciar Sesión
                                          BlocConsumer<AuthBloc, AuthState>(
                                            listener: (context, state) {
                                              if (!mounted) return;

                                              if (state.status == AuthStatus.error) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(state.errorMessage ?? 'Error desconocido'),
                                                    backgroundColor: Theme.of(context).colorScheme.error,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    margin: const EdgeInsets.all(16),
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                              else if (state.isAuthenticatedPatient || state.isAuthenticatedPsychologist) {
                                                final user = FirebaseAuth.instance.currentUser;
                                                
                                                if (user != null && !user.emailVerified) {
                                                  final userRole = state.isAuthenticatedPatient ? 'patient' : 'psychologist';
                                                  
                                                  Navigator.of(context).pushReplacement(
                                                    MaterialPageRoute(
                                                      builder: (context) => EmailVerificationScreen(
                                                        userEmail: user.email ?? '',
                                                        userRole: userRole,
                                                      ),
                                                    ),
                                                  );
                                                }
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
                                                                  children: [
                                                                    Icon(
                                                                      Icons.warning_amber_rounded,
                                                                      color: Theme.of(context).colorScheme.onError,
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    const Expanded(
                                                                      child: Text(
                                                                        'Por favor completa todos los campos correctamente.',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                backgroundColor: const Color.fromARGB(221, 255, 10, 10),
                                                                behavior: SnackBarBehavior.floating,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                margin: const EdgeInsets.all(16),
                                                                duration: const Duration(seconds: 3),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  style: ElevatedButton.styleFrom(
                                                    elevation: 4,
                                                    backgroundColor: null,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(
                                                        ResponsiveUtils.getBorderRadius(context, 16),
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets.all(0),
                                                  ),
                                                  child: Ink(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Theme.of(context).colorScheme.primary,
                                                          Theme.of(context).colorScheme.primaryContainer,
                                                        ],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(
                                                        ResponsiveUtils.getBorderRadius(context, 16),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: state.status == AuthStatus.loading
                                                          ? SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Theme.of(context).colorScheme.onPrimary,
                                                              ),
                                                            )
                                                          : FittedBox(
                                                              fit: BoxFit.scaleDown,
                                                              child: Text(
                                                                'Iniciar Sesión',
                                                                style: TextStyle(
                                                                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          SizedBox(height: screenHeight * 0.015),

                                          // ✅ Enlace "Crear Cuenta"
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                                      RoleSelectionScreen(),
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    const begin = Offset(1.0, 0.0);
                                                    const end = Offset.zero;
                                                    const curve = Curves.ease;
                                                    var tween = Tween(begin: begin, end: end)
                                                        .chain(CurveTween(curve: curve));
                                                    return SlideTransition(
                                                      position: animation.drive(tween),
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: ResponsiveUtils.getVerticalSpacing(context, 6),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      fontSize: ResponsiveUtils.getFontSize(context, 11),
                                                      color: const Color.fromARGB(255, 0, 0, 0),
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    children: const [
                                                      TextSpan(text: '¿No tienes una cuenta? '),
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // ✅ Espaciado inferior flexible (menor en landscape)
                            if (!isLandscape) 
                              Flexible(flex: 3, child: Container()),
                            if (isLandscape)
                              SizedBox(height: screenHeight * 0.05),
                            
                            // ✅ Footer "AURORA"
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
                                top: isLandscape 
                                    ? ResponsiveUtils.getVerticalSpacing(context, 4)
                                    : ResponsiveUtils.getVerticalSpacing(context, 8),
                              ),
                              child: FittedBox(
                                child: Text(
                                  'AURORA',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getFontSize(context, 10),
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                            ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}