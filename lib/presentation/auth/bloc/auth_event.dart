// lib/presentation/auth/bloc/auth_event.dart

import 'package:equatable/equatable.dart'; 
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent(); 

  @override
  List<Object?> get props => []; 
}


class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested(); 

  @override
  List<Object?> get props => []; 
}
class AuthRegisterPatientRequested extends AuthEvent {
  final String email;
  final String password;
  final String username; 
  final String phoneNumber;
  final DateTime dateOfBirth;

  const AuthRegisterPatientRequested({
    required this.email,
    required this.password,
    required this.username, 
    required this.phoneNumber,
    required this.dateOfBirth,
  });

  @override
  List<Object?> get props => [email, password, username, phoneNumber, dateOfBirth];
}

class AuthRegisterPsychologistRequested extends AuthEvent {
  final String email;
  final String password;
  final String username; 
  final String phoneNumber;
  final String professionalLicense;
  final DateTime dateOfBirth;

  const AuthRegisterPsychologistRequested({
    required this.email,
    required this.password,
    required this.username, 
    required this.phoneNumber,
    required this.professionalLicense,
    required this.dateOfBirth,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        username,
        phoneNumber,
        professionalLicense,
        dateOfBirth,
      ];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested(); 
}

class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;
  final dynamic userProfile; 
  final UserRole userRole; 

  const AuthStatusChanged(this.status, this.userProfile, {this.userRole = UserRole.unknown});

  @override
  List<Object?> get props => [status, userProfile, userRole];
}


class AuthStarted extends AuthEvent {
  const AuthStarted();
}