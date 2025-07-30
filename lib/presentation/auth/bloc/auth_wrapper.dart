// lib/presentation/auth/bloc/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/splash_screen.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (state.userRole == UserRole.patient) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PatientHomeScreen()),
            );
          } else if (state.userRole == UserRole.psychologist) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PsychologistHomeScreen()),
            );
          }
        } else if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state.status == AuthStatus.loading ||
            state.status == AuthStatus.unknown) {
          return const SplashScreen();
        }
        return const SizedBox.shrink(); // Navegación ocurre en listener
      },
    );
  }
}
