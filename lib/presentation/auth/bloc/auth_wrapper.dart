// lib/presentation/auth/bloc/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart'; 
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart'; 
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart'; 
import 'package:ai_therapy_teteocan/splash_screen.dart'; 
import 'dart:developer'; // Para los logs

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isError && state.errorMessage != null) {
          log(
            '🔴 AuthWrapper Listener: Error de autenticación: ${state.errorMessage}',
            name: 'AuthWrapper',
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (!state.isAuthenticated) {
          log(
            '🔴 AuthWrapper Listener: Usuario no autenticado, debería mostrar LoginScreen',
            name: 'AuthWrapper',
          );
        }
      },
      builder: (context, state) {
        log(
          '🟢 AuthWrapper Builder: Estado actual del AuthBloc: ${state.status}',
          name: 'AuthWrapper',
        );

        if (state.isUnknown || state.isLoading) {
          
          log(
            '🟢 AuthWrapper Builder: Mostrando SplashScreen.',
            name: 'AuthWrapper',
          );
          return const SplashScreen();
        } else if (state.isAuthenticated) {
          
          if (state.isAuthenticatedPatient) {
            log(
              '🟢 AuthWrapper Builder: Mostrando PatientHomeScreen.',
              name: 'AuthWrapper',
            );
            return PatientHomeScreen();
          } else if (state.isAuthenticatedPsychologist) {
            log(
              '🟢 AuthWrapper Builder: Mostrando PsychologistHomeScreen.',
              name: 'AuthWrapper',
            );
            return PsychologistHomeScreen();
          } else {
           
            log(
              '🔴 AuthWrapper Builder: Estado autenticado sin rol definido. Volviendo a LoginScreen.',
              name: 'AuthWrapper',
            );
            return const LoginScreen();
          }
        } else {
         
          log(
            '🟢 AuthWrapper Builder: Mostrando LoginScreen.',
            name: 'AuthWrapper',
          );
          return const LoginScreen();
        }
      },
    );
  }
}
