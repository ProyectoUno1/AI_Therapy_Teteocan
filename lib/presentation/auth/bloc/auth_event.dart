// lib/presentation/auth/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  // Cambiar List<Object> a List<Object?> para permitir valores nulos
  List<Object?> get props => [];
}

class AuthUserChanged extends AuthEvent {
  final String? firebaseUid; // Firebase UID
  final String? userRole; // Rol del usuario (paciente/psicólogo)
  final String? userName; // Nombre del usuario

  const AuthUserChanged({this.firebaseUid, this.userRole, this.userName});

  @override
  List<Object?> get props => [firebaseUid, userRole, userName];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterPatientRequested extends AuthEvent {
  final String username;
  final String email;
  final String phoneNumber;
  final String password;
  

  const AuthRegisterPatientRequested({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [username, email, phoneNumber, password];
}

class AuthRegisterPsychologistRequested extends AuthEvent {
  final String username;
  final String email;
  final String phoneNumber;
  final String professionalId;
  final String password;

  const AuthRegisterPsychologistRequested({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.professionalId,
    required this.password,
  });

  @override
  List<Object> get props => [
    username,
    email,
    phoneNumber,
    professionalId,
    password,
  ];
}

class AuthLogoutRequested extends AuthEvent {}
