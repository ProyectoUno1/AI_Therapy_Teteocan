// lib/presentation/auth/bloc/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/splash_screen.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importaciones para EmotionBloc y HomeContentCubit
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/data/repositories/emotion_repository.dart';
import 'package:ai_therapy_teteocan/data/datasources/emotion_data_source.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  Widget build(BuildContext context) {

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!mounted) return;
        if (state.isError && state.errorMessage != null) {
          log(
            ' AuthWrapper Listener: Error de autenticación - ${state.errorMessage}',
            name: 'AuthWrapper',
          );
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        } else if (state.isAuthenticated && state.isAuthenticatedPsychologist) {
          log(
            ' AuthWrapper Listener: Psicólogo autenticado, navegando a PsychologistHomeScreen',
            name: 'AuthWrapper',
          );
        } else {
          log(
            ' AuthWrapper Listener: Usuario no autenticado, debería mostrar LoginScreen',
            name: 'AuthWrapper',
          );
        }
      },
      builder: (context, state) {
        log(
          ' AuthWrapper Builder: Estado actual del AuthBloc: ${state.status}',
          name: 'AuthWrapper',
        );

        if (state.isUnknown || state.isLoading) {
          log(
            ' AuthWrapper Builder: Mostrando SplashScreen.',
            name: 'AuthWrapper',
          );
          return const SplashScreen();
        } else if (state.isAuthenticated) {
          if (state.isAuthenticatedPatient) {
            log(
              ' AuthWrapper Builder: Mostrando PatientHomeScreen.',
              name: 'AuthWrapper',
            );
            
            // Crear EmotionBloc y HomeContentCubit específicos para el paciente
            final emotionBloc = EmotionBloc(
              emotionRepository: EmotionRepositoryImpl(
                dataSource: EmotionRemoteDataSource(baseUrl: ApiConstants.baseUrl),
              ),
            );
            
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: emotionBloc),
                BlocProvider<HomeContentCubit>(
                  create: (context) => HomeContentCubit(
                    emotionBloc: emotionBloc,
                    patientId: state.patient!.uid, // Usar el ID del paciente autenticado
                  ),
                ),
              ],
              child: PatientHomeScreen(),
            );
            
          } else if (state.isAuthenticatedPsychologist) {
            log(
              ' AuthWrapper Builder: Mostrando PsychologistHomeScreen.',
              name: 'AuthWrapper',
            );
            return PsychologistHomeScreen();
          } else {
            log(
              ' AuthWrapper Builder: Estado autenticado sin rol definido. Volviendo a LoginScreen.',
              name: 'AuthWrapper',
            );
            return const LoginScreen();
          }
        } else {
          log(
            ' AuthWrapper Builder: Mostrando LoginScreen.',
            name: 'AuthWrapper',
          );
          return const LoginScreen();
        }
      },
    );
  }
}