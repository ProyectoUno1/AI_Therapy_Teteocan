// lib/presentation/auth/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
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
  final String? errorMessage;
  final UserRole userRole;
  final PatientModel? patient;
  final PsychologistModel? psychologist;

  
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error; 
  bool get isSuccess => status == AuthStatus.success;
  bool get isUnknown => status == AuthStatus.unknown;

  bool get isAuthenticatedPatient => status == AuthStatus.authenticated && userRole == UserRole.patient && patient != null;
  bool get isAuthenticatedPsychologist => status == AuthStatus.authenticated && userRole == UserRole.psychologist && psychologist != null;


  const AuthState({
    this.status = AuthStatus.unknown,
    this.errorMessage,
    this.userRole = UserRole.unknown,
    this.patient,
    this.psychologist,
  });

  const AuthState.authenticated({
    required this.userRole,
    this.patient,
    this.psychologist,
  })  : status = AuthStatus.authenticated,
        errorMessage = null,
        assert(
          (userRole == UserRole.patient && patient != null && psychologist == null) ||
              (userRole == UserRole.psychologist && psychologist != null && patient == null),
          'Authenticated state must have a user (patient or psychologist) matching the role.',
        );

  const AuthState.unauthenticated({
    this.errorMessage,
  })  : status = AuthStatus.unauthenticated,
        userRole = UserRole.unknown,
        patient = null,
        psychologist = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        errorMessage = null,
        userRole = UserRole.unknown,
        patient = null,
        psychologist = null;

  const AuthState.error({
    this.errorMessage,
  })  : status = AuthStatus.error,
        userRole = UserRole.unknown,
        patient = null,
        psychologist = null;

  const AuthState.success({
    this.errorMessage,
  })  : status = AuthStatus.success,
        userRole = UserRole.unknown,
        patient = null,
        psychologist = null;

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        errorMessage = null,
        userRole = UserRole.unknown,
        patient = null,
        psychologist = null;

  // Tu método copyWith existente
  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserRole? userRole,
    PatientModel? patient,
    PsychologistModel? psychologist,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userRole: userRole ?? this.userRole,
      patient: patient == null ? null : (patient is PatientModel ? patient : this.patient),
      psychologist: psychologist == null ? null : (psychologist is PsychologistModel ? psychologist : this.psychologist),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        userRole,
        patient,
        psychologist,
      ];
}