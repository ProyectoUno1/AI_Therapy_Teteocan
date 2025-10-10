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
        if (state.isLoading) {
          log('AuthWrapper: Mostrando SplashScreen', name: 'AuthWrapper');
          return const SplashScreen();
        }

        if (state.isAuthenticatedPatient) {
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
          return const PsychologistHomeScreen();
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && !currentUser.emailVerified) {
          String userRole = 'patient';
          if (state.userRole == UserRole.psychologist) {
            userRole = 'psychologist';
          }

          return EmailVerificationScreen(
            userEmail: currentUser.email ?? '',
            userRole: userRole,
          );
        }
        return const LoginScreen();
      },
    );
  }
}
