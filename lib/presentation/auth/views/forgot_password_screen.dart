// lib/presentation/auth/views/forgot_password_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/input_validators.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.03),

                            // Botón de regreso
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Theme.of(context).textTheme.headlineMedium?.color,
                                  size: ResponsiveUtils.getIconSize(context, 24),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.02),

                            // Logo
                            SizedBox(
                              width: ResponsiveUtils.getLogoWidth(context) * 0.8,
                              height: ResponsiveUtils.getLogoHeight(context) * 0.8,
                              child: Image.asset(
                                AppConstants.logoAuroraPath,
                                fit: BoxFit.contain,
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.03),

                            Text(
                              'Recuperar Contraseña',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                                fontFamily: 'Poppins',
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.015),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, 13),
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.04),

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
                                  child: Form(
                                    key: _formKey,
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
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: 14,
                                          placeholderColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),

                                        SizedBox(height: isMobile ? 20 : 24),

                                        BlocConsumer<AuthBloc, AuthState>(
                                          listener: (context, state) {
                                            if (!mounted) return;

                                            if (state.status == AuthStatus.error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      state.errorMessage ?? 'Error desconocido'),
                                                  backgroundColor:
                                                      Theme.of(context).colorScheme.error,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  margin: const EdgeInsets.all(16),
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                            } else if (state.status == AuthStatus.success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle_outline,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          state.errorMessage ??
                                                              'Correo enviado exitosamente',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  margin: const EdgeInsets.all(16),
                                                  duration: const Duration(seconds: 4),
                                                ),
                                              );
                                              Future.delayed(const Duration(seconds: 2), () {
                                                if (mounted) {
                                                  Navigator.of(context).pop();
                                                }
                                              });
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
                                                        if (_formKey.currentState?.validate() ??
                                                            false) {
                                                          context.read<AuthBloc>().add(
                                                                AuthPasswordResetRequested(
                                                                  email: _emailController.text,
                                                                ),
                                                              );
                                                        } else {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons.warning_amber_rounded,
                                                                    color: Theme.of(context)
                                                                        .colorScheme
                                                                        .onError,
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  const Expanded(
                                                                    child: Text(
                                                                      'Por favor ingresa un email válido.',
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  const Color.fromARGB(
                                                                      221, 255, 10, 10),
                                                              behavior: SnackBarBehavior.floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(12),
                                                              ),
                                                              margin: const EdgeInsets.all(16),
                                                              duration:
                                                                  const Duration(seconds: 3),
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
                                                  padding: const EdgeInsets.all(0),
                                                ),
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Theme.of(context).colorScheme.primary,
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Center(
                                                    child: state.status == AuthStatus.loading
                                                        ? CircularProgressIndicator(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onPrimary,
                                                          )
                                                        : Text(
                                                            'Enviar Enlace',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  ResponsiveUtils.getFontSize(
                                                                      context, 16),
                                                              fontWeight: FontWeight.w600,
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                              fontFamily: 'Poppins',
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Enlace para volver al login
                                        InkWell(
                                          onTap: () => Navigator.of(context).pop(),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize:
                                                      ResponsiveUtils.getFontSize(context, 11),
                                                  color: const Color.fromARGB(255, 0, 0, 0),
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                children: const [
                                                  TextSpan(
                                                    text: '¿Recordaste tu contraseña? ',
                                                  ),
                                                  TextSpan(
                                                    text: 'Iniciar Sesión',
                                                    style: TextStyle(
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ],
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

                            // Espaciado flexible
                            SizedBox(height: constraints.maxHeight * 0.05),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'AURORA',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, 10),
                                  color: Colors.black26,
                                  letterSpacing: 2.0,
                                  fontFamily: 'Poppins',
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
    super.dispose();
  }
}