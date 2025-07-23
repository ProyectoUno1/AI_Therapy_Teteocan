// lib/presentation/auth/bloc/auth_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/user/get_user_role_usecase.dart'; // Aunque el rol ya lo devuelve el repo de auth
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  // final GetUserRoleUseCase _getUserRoleUseCase; // No es necesario si el repo de auth ya trae el rol

  late StreamSubscription<UserEntity?> _userSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required RegisterUserUseCase registerUserUseCase,
    // required GetUserRoleUseCase getUserRoleUseCase,
  }) : _authRepository = authRepository,
       _signInUseCase = signInUseCase,
       _registerUserUseCase = registerUserUseCase,
       // _getUserRoleUseCase = getUserRoleUseCase,
       super(const AuthState.unknown()) {
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterPatientRequested>(_onAuthRegisterPatientRequested);
    on<AuthRegisterPsychologistRequested>(_onAuthRegisterPsychologistRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    _userSubscription = _authRepository.authStateChanges.listen((user) {
      add(
        AuthUserChanged(
          firebaseUid: user?.uid,
          userRole: user?.role,
          userName: user?.username,
        ),
      );
    });
  }

  void _onAuthUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.firebaseUid == null) {
      emit(const AuthState.unauthenticated());
    } else {
      // Aquí el `user` ya debería venir con el rol del backend
      final user = UserEntity(
        uid: event.firebaseUid!,
        username: event.userName ?? 'Usuario',
        email: '', // El email no viene en AuthUserChanged directamente
        phoneNumber: '', // El número no viene en AuthUserChanged directamente
        role: event.userRole ?? 'unknown',
      );

      if (user.role == 'paciente') {
        emit(AuthState.authenticatedPatient(user));
      } else if (user.role == 'psicologo') {
        emit(AuthState.authenticatedPsychologist(user));
      } else {
        emit(
          const AuthState.unauthenticated(),
        ); // Rol desconocido, forzar logout
        _authRepository.signOut(); // Asegurarse de cerrar sesión
      }
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      // El AuthUserChanged listener se encargará de emitir el estado correcto
      // después de que _signInUseCase actualice el estado de autenticación de Firebase.
      // No emitimos un estado final aquí para evitar inconsistencias.
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(
        const AuthState.unauthenticated(),
      ); // Volver a unauthenticated después del error
    } catch (e) {
      emit(AuthState.error('Error inesperado al iniciar sesión.'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthRegisterPatientRequested(
    AuthRegisterPatientRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final user = await _registerUserUseCase.registerPatient(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
      );
      // Similar al login, el listener de AuthUserChanged manejará el estado final.
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Error inesperado al registrar paciente.'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthRegisterPsychologistRequested(
    AuthRegisterPsychologistRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final user = await _registerUserUseCase.registerPsychologist(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        professionalId: event.professionalId,
      );
      // Similar al login, el listener de AuthUserChanged manejará el estado final.
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Error inesperado al registrar psicólogo.'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(const AuthState.unauthenticated());
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(
        const AuthState.unauthenticated(),
      ); // Asegurarse de que el estado sea unauthenticated
    } catch (e) {
      emit(AuthState.error('Error inesperado al cerrar sesión.'));
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
