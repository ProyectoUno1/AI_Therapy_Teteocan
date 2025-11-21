import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_patient_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_wrapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const EmailVerificationScreen({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _canResendEmail = true;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        try {
          await FirebaseAuth.instance.currentUser?.reload();
          final user = FirebaseAuth.instance.currentUser;
          if (user?.emailVerified ?? false) {
            timer.cancel();
            
            if (mounted) {
              _resendTimer?.cancel();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Email verificado exitosamente!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
              
              await Future.delayed(const Duration(milliseconds: 1000));
              
              if (mounted) {
                context.read<AuthBloc>().add(AuthCheckEmailVerification());
                await Future.delayed(const Duration(milliseconds: 500));
                
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          print('Error verificando email: $e');
        }
      },
    );
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Correo de verificación enviado'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _canResendEmail = false;
            _resendCountdown = 60;
          });

          _resendTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              setState(() {
                _resendCountdown--;
              });

              if (_resendCountdown <= 0) {
                timer.cancel();
                setState(() {
                  _canResendEmail = true;
                });
              }
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar correo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkVerificationManually() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified ?? false) {
        if (mounted) {
          _verificationCheckTimer?.cancel();
          _resendTimer?.cancel();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Email verificado exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (mounted) {
            context.read<AuthBloc>().add(AuthCheckEmailVerification());
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AuthWrapper(),
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aún no se ha verificado el email'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditEmailDialog() async {
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Email incorrecto?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Si te equivocaste al escribir tu email, eliminaremos esta cuenta y podrás registrarte nuevamente con el correo correcto.\n\n¿Deseas continuar?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sí, corregir email',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (shouldChange != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _verificationCheckTimer?.cancel();
        _resendTimer?.cancel();

        final collection = widget.userRole == 'patient' ? 'patients' : 'psychologists';
        
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .delete();
        
        await user.delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta eliminada. Por favor regístrate nuevamente.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(seconds: 1));
          
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RegisterPatientScreen(),
              ),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Error al eliminar cuenta';
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Por seguridad, cierra sesión y vuelve a intentarlo';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      _verificationCheckTimer?.cancel();
      _resendTimer?.cancel();
      if (mounted) {
        context.read<AuthBloc>().add(AuthSignOutRequested());
      }
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
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
                            SizedBox(height: constraints.maxHeight * 0.05),
                            
                            Icon(
                              Icons.mark_email_unread_outlined,
                              size: ResponsiveUtils.getIconSize(context, 80),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.03),
                            
                            Text(
                              'Verifica tu correo',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 24),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.02),
                            
                            Text(
                              'Hemos enviado un correo de verificación a:',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 14),
                                color: Colors.black54,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.userEmail,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(context, 16),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: _showEditEmailDialog,
                                  tooltip: 'Corregir email',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.03),
                            
                            Container(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Por favor, revisa tu correo y haz clic en el enlace de verificación.',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(context, 13),
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nota: Puede tardar unos minutos en llegar. Revisa tu carpeta de spam.',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(context, 11),
                                      color: Colors.black54,
                                      fontFamily: 'Poppins',
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.04),
                            
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveUtils.getButtonHeight(context),
                              child: ElevatedButton.icon(
                                onPressed: _checkVerificationManually,
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                label: Text(
                                  'Ya verifiqué mi correo',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.02),
                            
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveUtils.getButtonHeight(context),
                              child: ElevatedButton(
                                onPressed: _canResendEmail ? _sendVerificationEmail : null,
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
                                    gradient: LinearGradient(
                                      colors: _canResendEmail
                                          ? [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.primaryContainer,
                                            ]
                                          : [Colors.grey, Colors.grey],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _canResendEmail
                                          ? 'Reenviar Correo'
                                          : 'Espera ${_resendCountdown}s',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getFontSize(context, 14),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: constraints.maxHeight * 0.05),
                            
                            TextButton(
                              onPressed: _signOut,
                              child: Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                                  color: Colors.black54,
                                  fontFamily: 'Poppins',
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
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
}