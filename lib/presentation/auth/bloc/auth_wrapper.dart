import 'dart:developer';

import 'package:ai_therapy_teteocan/data/repositories/user_repository_impl.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/usecases/user/get_user_role_usecase.dart';
import 'package:ai_therapy_teteocan/presentation/admin/views/psychologists_list_page.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final GetUserRoleUseCase getUserRoleUseCase;
  
  @override
  void initState() {
    super.initState();
    // Aquí necesitas pasar la implementación de UserRepository real
    getUserRoleUseCase = GetUserRoleUseCase(UserRepositoryImpl());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isError && state.errorMessage != null) {
          log('AuthWrapper Listener: Error de autenticación: ${state.errorMessage}', name: 'AuthWrapper');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!))
          );
        }
      },
      builder: (context, state) {
        log('AuthWrapper Builder: Estado actual del AuthBloc: ${state.status}', name: 'AuthWrapper');

        if (state.isUnknown || state.isLoading) {
          return const SplashScreen();
        } else if (state.isAuthenticated) {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          return FutureBuilder<UserEntity>(
            future: getUserRoleUseCase.call(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const LoginScreen();
              }

              final role = snapshot.data!.role;

              if (role == "admin") {
                return AdminPanel();
              } else if (role == "patient") {
                return PatientHomeScreen();
              } else if (role == "psychologist") {
                return PsychologistHomeScreen();
              } else {
                return const LoginScreen(); // rol desconocido
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
