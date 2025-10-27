// lib/presentation/auth/bloc/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/email_verification_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/splash_screen.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _shouldShowProfessionalSetupDialog = false;

  void _checkIfShouldShowDialog(AuthState state) {
    if (state.isAuthenticatedPsychologist) {
      final psychologist = state.psychologist;

      final hasCompletedProfile =
          psychologist?.specialty != null &&
          psychologist?.specialty != '' &&
          psychologist?.professionalTitle != null;

      if (!hasCompletedProfile) {
        setState(() {
          _shouldShowProfessionalSetupDialog = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticatedPsychologist) {
          _checkIfShouldShowDialog(state);
        }
      },
      buildWhen: (previous, current) {
        final shouldRebuild =
            previous.status != current.status ||
            previous.patient != current.patient ||
            previous.psychologist != current.psychologist;

        return shouldRebuild;
      },
      builder: (context, state) {
        // 🔍 AGREGAR ESTOS LOGS DE DIAGNÓSTICO AQUÍ
        log('🔐 AuthWrapper State: ${state.status}', name: 'AuthWrapper');
        log('🔐 isAuthenticatedPatient: ${state.isAuthenticatedPatient}', name: 'AuthWrapper');
        log('🔐 isAuthenticatedPsychologist: ${state.isAuthenticatedPsychologist}', name: 'AuthWrapper');
        log('🔐 Patient: ${state.patient != null}', name: 'AuthWrapper');
        log('🔐 Psychologist: ${state.psychologist != null}', name: 'AuthWrapper');
        log('🔐 UserRole: ${state.userRole}', name: 'AuthWrapper');
        log('🔐 Error: ${state.errorMessage}', name: 'AuthWrapper');
        log('🔐 Firebase User: ${FirebaseAuth.instance.currentUser != null}', name: 'AuthWrapper');
        if (FirebaseAuth.instance.currentUser != null) {
          log('🔐 Email verificado: ${FirebaseAuth.instance.currentUser!.emailVerified}', name: 'AuthWrapper');
        }

        if (state.isLoading) {
          log('AuthWrapper: Mostrando SplashScreen', name: 'AuthWrapper');
          return const SplashScreen();
        }

        if (state.isAuthenticatedPatient) {
          log('🎯 AuthWrapper: Redirigiendo a PatientHomeScreen', name: 'AuthWrapper');
          return MultiBlocProvider(
            providers: [
              BlocProvider<HomeContentCubit>(
                create: (context) => HomeContentCubit(
                  emotionBloc: context.read<EmotionBloc>(),
                  patientId: state.patient!.uid,
                ),
              ),
            ],
            child: const PatientHomeScreen(),
          );
        }
        if (state.isAuthenticatedPsychologist) {
          log('🎯 AuthWrapper: Redirigiendo a PsychologistHomeScreen', name: 'AuthWrapper');
          return const PsychologistHomeScreen();
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && !currentUser.emailVerified) {
          log('📧 AuthWrapper: Mostrando EmailVerificationScreen', name: 'AuthWrapper');
          String userRole = 'patient';
          if (state.userRole == UserRole.psychologist) {
            userRole = 'psychologist';
          }

          return EmailVerificationScreen(
            userEmail: currentUser.email ?? '',
            userRole: userRole,
          );
        }
        
        log('🚪 AuthWrapper: Mostrando LoginScreen', name: 'AuthWrapper');
        return const LoginScreen();
      },
    );
  }
}