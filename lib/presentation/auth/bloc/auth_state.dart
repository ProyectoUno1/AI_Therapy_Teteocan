// lib/presentation/auth/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

enum AuthStatus {
  unknown,               // Estado inicial, cargando
  success,               // Estado genérico de éxito (login o registro correcto)
  authenticatedPatient,  // Autenticado como paciente 
  authenticatedPsychologist, // Autenticado como psicólogo 
  unauthenticated,       // No autenticado
  loading,               // Para operaciones en curso (login/registro)
  error,                 // Error en login/registro
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user; // Puede ser PatientEntity o PsychologistEntity
  final String? errorMessage;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  // Constructores para estados específicos
  const AuthState.unknown() : this._();
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
  const AuthState.success(UserEntity user) : this._(status: AuthStatus.success, user: user);
  const AuthState.authenticatedPatient(UserEntity user) : this._(status: AuthStatus.authenticatedPatient, user: user);
  const AuthState.authenticatedPsychologist(UserEntity user) : this._(status: AuthStatus.authenticatedPsychologist, user: user);
  const AuthState.error(String message) : this._(status: AuthStatus.error, errorMessage: message);

  // Método para saber si está autenticado en cualquiera de las formas
  bool get isAuthenticated =>
      status == AuthStatus.authenticatedPatient ||
      status == AuthStatus.authenticatedPsychologist ||
      status == AuthStatus.success;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
