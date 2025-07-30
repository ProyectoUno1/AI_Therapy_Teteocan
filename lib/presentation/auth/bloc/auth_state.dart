// lib/presentation/auth/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart'; 
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart'; 

enum AuthStatus {
  unknown, // Estado inicial, mientras se verifica la autenticación
  loading, // Cargando alguna operación de autenticación
  authenticated, // El usuario está logueado
  unauthenticated, // El usuario no está logueado
  error, // Hubo un error en la autenticación
  success, // Operación (ej. registro) fue exitosa
}

enum UserRole {
  unknown, // Rol aún no determinado o no aplicable
  patient,
  psychologist,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final UserRole userRole;
  final PatientModel? patient; 
  final PsychologistModel? psychologist; 
  

 
  bool get isAuthenticatedPatient => status == AuthStatus.authenticated && userRole == UserRole.patient && patient != null;
  bool get isAuthenticatedPsychologist => status == AuthStatus.authenticated && userRole == UserRole.psychologist && psychologist != null;
  bool get isUnknown => status == AuthStatus.unknown;
  bool get isLoading => status == AuthStatus.loading;


  const AuthState({
    this.status = AuthStatus.unknown, // Default a unknown para el inicio de la app
    this.errorMessage,
    this.userRole = UserRole.unknown,
    this.patient,
    this.psychologist,
  });

  // Constructor para estado autenticado
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

  // Constructores convenientes para otros estados
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
      // Manejo de nullable: si el nuevo valor es null, explícitamente se vuelve null
      patient: patient is PatientModel ? patient : (patient == null ? null : this.patient),
      psychologist: psychologist is PsychologistModel ? psychologist : (psychologist == null ? null : this.psychologist),
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