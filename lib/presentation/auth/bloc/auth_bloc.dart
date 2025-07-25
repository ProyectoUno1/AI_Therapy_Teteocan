import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final RegisterUserUseCase _registerUserUseCase;

  late StreamSubscription<UserEntity?> _userSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required RegisterUserUseCase registerUserUseCase,
  })  : _authRepository = authRepository,
        _signInUseCase = signInUseCase,
        _registerUserUseCase = registerUserUseCase,
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
      final user = UserEntity(
        uid: event.firebaseUid!,
        username: event.userName ?? 'Usuario',
        email: '',
        phoneNumber: '',
        role: event.userRole ?? 'unknown',
      );

      if (user.role == 'paciente') {
        emit(AuthState.authenticatedPatient(user));
      } else if (user.role == 'psicologo') {
        emit(AuthState.authenticatedPsychologist(user));
      } else {
        emit(const AuthState.unauthenticated());
        _authRepository.signOut();
      }
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      // El listener de AuthUserChanged emitirá el estado final.
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(const AuthState.unauthenticated());
    } catch (_) {
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
      await _registerUserUseCase.registerPatient(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        dateOfBirth: event.dateOfBirth, 
      );
      // Listener manejará el estado final
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(const AuthState.unauthenticated());
    } catch (_) {
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
      await _registerUserUseCase.registerPsychologist(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        professionalLicense: event.professionalLicense,
        specialty: event.specialty,
        schedule: event.schedule,
        aboutMe: event.aboutMe,
        dateOfBirth: event.dateOfBirth,
      );
      // Listener manejará el estado final
    } on AppException catch (e) {
      emit(AuthState.error(e.message));
      emit(const AuthState.unauthenticated());
    } catch (_) {
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
      emit(const AuthState.unauthenticated());
    } catch (_) {
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
