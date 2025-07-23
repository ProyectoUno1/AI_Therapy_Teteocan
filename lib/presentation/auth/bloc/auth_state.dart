// lib/presentation/auth/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

enum AuthStatus {
  unknown, // Estado inicial, cargando
  authenticatedPatient,
  authenticatedPsychologist,
  unauthenticated,
  loading, // Para operaciones de login/registro
  error, // Para errores de login/registro
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

  // Estados específicos
  const AuthState.unknown() : this._();
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);
  const AuthState.authenticatedPatient(UserEntity user)
    : this._(status: AuthStatus.authenticatedPatient, user: user);
  const AuthState.authenticatedPsychologist(UserEntity user)
    : this._(status: AuthStatus.authenticatedPsychologist, user: user);
  const AuthState.error(String message)
    : this._(status: AuthStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, user, errorMessage];
}
