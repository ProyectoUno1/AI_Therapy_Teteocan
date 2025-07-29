// lib/presentation/auth/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
  success,
}

enum UserRole {
  unknown,
  patient,
  psychologist,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final PatientModel? patient;
  final PsychologistModel? psychologist;
  final String? errorMessage;
  final UserRole userRole;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.patient,
    this.psychologist,
    this.errorMessage,
    this.userRole = UserRole.unknown,
  });

  AuthState copyWith({
    AuthStatus? status,
  
    Object? patient, 
    Object? psychologist, 
    String? errorMessage,
    UserRole? userRole,
  }) {
    final newStatus = status ?? this.status;
    final newUserRole = userRole ?? this.userRole;

    return AuthState(
      status: newStatus,
      
      patient: newStatus == AuthStatus.authenticated && newUserRole == UserRole.patient
          ? (patient is PatientModel ? patient : this.patient) 
          : null, 
      psychologist: newStatus == AuthStatus.authenticated && newUserRole == UserRole.psychologist
          ? (psychologist is PsychologistModel ? psychologist : this.psychologist) 
          : null,
      errorMessage: errorMessage, 
      userRole: newUserRole,
    );
  }


  bool get isAuthenticatedPatient =>
      status == AuthStatus.authenticated &&
      userRole == UserRole.patient && 
      patient != null;

  bool get isAuthenticatedPsychologist =>
      status == AuthStatus.authenticated &&
      userRole == UserRole.psychologist && 
      psychologist != null;

  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isUnknown => status == AuthStatus.unknown;

  @override
  List<Object?> get props => [status, patient, psychologist, errorMessage, userRole];
}