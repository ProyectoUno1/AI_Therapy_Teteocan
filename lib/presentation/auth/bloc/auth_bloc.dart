// lib/presentation/auth/bloc/auth_bloc.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final RegisterUserUseCase _registerUserUseCase;

  late StreamSubscription<dynamic> _userSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required RegisterUserUseCase registerUserUseCase,
  }) : _authRepository = authRepository,
        _signInUseCase = signInUseCase,
        _registerUserUseCase = registerUserUseCase,
        super(const AuthState.unknown()) {
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthRegisterPatientRequested>(_onAuthRegisterPatientRequested);
    on<AuthRegisterPsychologistRequested>(_onAuthRegisterPsychologistRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthStarted>(_onAuthStarted);
    on<UpdatePatientInfoRequested>(_onUpdatePatientInfoRequested);

    log(' AuthBloc: Inicializando _userSubscription para authStateChanges.', name: 'AuthBloc');
    _userSubscription = _authRepository.authStateChanges.listen((userProfile) {
      log(' AuthBloc Subscription: Recibido userProfile del repositorio: ${userProfile?.runtimeType}', name: 'AuthBloc');

      if (userProfile == null) {
        log(' AuthBloc Subscription: Firebase User es null. Añadiendo AuthStatusChanged para UNATHENTICATED.', name: 'AuthBloc');
        add(const AuthStatusChanged(AuthStatus.unauthenticated, null, userRole: UserRole.unknown));
      } else if (userProfile is PatientModel) {
        log(' AuthBloc Subscription: userProfile es PatientModel. Añadiendo AuthStatusChanged para AUTHENTICATED (Patient).', name: 'AuthBloc');
        add(AuthStatusChanged(AuthStatus.authenticated, userProfile, userRole: UserRole.patient));
      } else if (userProfile is PsychologistModel) {
        log(' AuthBloc Subscription: userProfile es PsychologistModel. Añadiendo AuthStatusChanged para AUTHENTICATED (Psychologist).', name: 'AuthBloc');
        add(AuthStatusChanged(AuthStatus.authenticated, userProfile, userRole: UserRole.psychologist));
      } else {
        log(' AuthBloc Subscription: userProfile es de tipo inesperado: ${userProfile.runtimeType}. Forzando cierre de sesión.', name: 'AuthBloc');
        add(const AuthStatusChanged(AuthStatus.unauthenticated, null, userRole: UserRole.unknown, errorMessage: 'Perfil de usuario inesperado. Sesión cerrada.'));
        _authRepository.signOut();
      }
    });
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    log(' AuthBloc Event: AuthStarted recibido. No se emite estado aquí, la suscripción a authStateChanges lo maneja.', name: 'AuthBloc');
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    log('DEBUG AUTHBLOC: Inicia procesamiento de _onAuthStatusChanged para evento: ${event.status}', name: 'AuthBloc');
    log(' AuthBloc Event: AuthStatusChanged recibido. Nuevo estado: ${event.status}, Rol: ${event.userRole}, Perfil: ${event.userProfile?.runtimeType}, Mensaje Error: ${event.errorMessage}', name: 'AuthBloc');
    
    AuthState newState;

    switch (event.status) {
      case AuthStatus.authenticated:
        if (event.userRole == UserRole.patient && event.userProfile is PatientModel) {
          newState = AuthState.authenticated(
            userRole: UserRole.patient,
            patient: event.userProfile as PatientModel,
          );
        } else if (event.userRole == UserRole.psychologist && event.userProfile is PsychologistModel) {
          newState = AuthState.authenticated(
            userRole: UserRole.psychologist,
            psychologist: event.userProfile as PsychologistModel,
          );
        } else {
          log(' AuthBloc Event: AuthStatusChanged (authenticated) con rol/perfil inconsistente. Forzando unauthenticated.', name: 'AuthBloc');
          newState = AuthState.unauthenticated(errorMessage: event.errorMessage ?? 'Rol o perfil inconsistente. Sesión cerrada.');
          _authRepository.signOut();
        }
        break;
      case AuthStatus.unauthenticated:
        newState = AuthState.unauthenticated(errorMessage: event.errorMessage);
        break;
      case AuthStatus.loading:
        newState = const AuthState.loading();
        break;
      case AuthStatus.error:
        newState = AuthState.error(errorMessage: event.errorMessage);
        break;
      case AuthStatus.success:
        newState = AuthState.success(errorMessage: event.errorMessage);
        break;
      case AuthStatus.unknown:
      default:
        newState = const AuthState.unknown();
        break;
    }

    if (state != newState) {
      emit(newState);
      log(' AuthBloc Emitió: Nuevo estado: ${newState.status}. Detalle: ${newState.userRole}, Patient: ${newState.patient != null}, Psychologist: ${newState.psychologist != null}, Error: ${newState.errorMessage}', name: 'AuthBloc');
    } else {
      log(' AuthBloc NO EMITIÓ: Nuevo estado es idéntico al actual (${newState.status}). Equatable funcionó.', name: 'AuthBloc');
    }
  }

  Future<void> _onUpdatePatientInfoRequested(
    UpdatePatientInfoRequested event,
    Emitter<AuthState> emit,
  ) async {
    
    if (state.isAuthenticatedPatient) {
      final user = state.patient!; 
      
      emit(const AuthState.loading());
      try {
        await _authRepository.updatePatientInfo(
          userId: user.uid,
          name: event.name,
          dob: event.dob,
          phone: event.phone,
        );
        
        final updatedPatient = await _authRepository.getPatientData(user.uid);
        emit(const AuthState.success(errorMessage: 'Perfil actualizado exitosamente.'));
        emit(AuthState.authenticated(userRole: UserRole.patient, patient: updatedPatient));
      } on AppException catch (e) {
        emit(AuthState.error(errorMessage: e.message));
      } catch (e) {
        emit(const AuthState.error(errorMessage: 'Ocurrió un error inesperado al actualizar el perfil.'));
      }
    } else {
      emit(const AuthState.error(errorMessage: 'No tienes permiso para actualizar este perfil.'));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    log(' AuthBloc Event: AuthSignInRequested para ${event.email}', name: 'AuthBloc');
    emit(const AuthState.loading());

    try {
      await _signInUseCase(email: event.email, password: event.password);
      log(' AuthBloc Event: SignInUseCase completado. Esperando emisión de authStateChanges.', name: 'AuthBloc');
      
    } on AppException catch (e) {
      log(' AuthBloc Event: Error de AppException al iniciar sesión: ${e.message}', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: e.message));
    } catch (e) {
      log(' AuthBloc Event: Error inesperado al iniciar sesión: $e', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: 'Error inesperado al iniciar sesión: $e'));
    }
  }

  Future<void> _onAuthRegisterPatientRequested(
  AuthRegisterPatientRequested event,
  Emitter<AuthState> emit,
) async {
  log(' AuthBloc Event: AuthRegisterPatientRequested para ${event.email}', name: 'AuthBloc');
  emit(const AuthState.loading());

  try {
    await _authRepository.registerPatient(
      email: event.email,
      password: event.password,
      username: event.username,
      phoneNumber: event.phoneNumber,
      dateOfBirth: event.dateOfBirth,
    );

    log(' AuthBloc: Registro exitoso, iniciando sesión automática para ${event.email}', name: 'AuthBloc');

    await _signInUseCase(email: event.email, password: event.password);

  } on AppException catch (e) {
    log(' AuthBloc: Error de AppException al registrar paciente: ${e.message}', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: e.message));
  } catch (e) {
    log(' AuthBloc: Error inesperado al registrar paciente: $e', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: 'Error inesperado al registrar paciente: $e'));
  }
}
  Future<void> _onAuthRegisterPsychologistRequested(
    AuthRegisterPsychologistRequested event,
    Emitter<AuthState> emit,
  ) async {
    log(' AuthBloc Event: AuthRegisterPsychologistRequested para ${event.email}', name: 'AuthBloc');
    emit(const AuthState.loading());

    try {
      await _registerUserUseCase.registerPsychologist(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        professionalLicense: event.professionalLicense,
        dateOfBirth: event.dateOfBirth,
      );

      log(' AuthBloc Event: Registro de psicólogo completado. Forzando cierre de sesión.', name: 'AuthBloc');
      await _signInUseCase(email: event.email, password: event.password);
    } on AppException catch (e) {
      log(' AuthBloc Event: Error de AppException al registrar psicólogo: ${e.message}', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: e.message));
    } catch (e) {
      log(' AuthBloc Event: Error inesperado al registrar psicólogo: $e', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: 'Error inesperado al registrar psicólogo: $e'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    log(' AuthBloc Event: AuthSignOutRequested recibido.', name: 'AuthBloc');
    emit(const AuthState.loading());
    try {
      await _authRepository.signOut();
      log(' AuthBloc Event: SignOut completado. Esperando emisión de authStateChanges (unauthenticated).', name: 'AuthBloc');

    } on AppException catch (e) {
      log(' AuthBloc Event: Error de AppException al cerrar sesión: ${e.message}', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: e.message));
    } catch (e) {
      log(' AuthBloc Event: Error inesperado al cerrar sesión: $e', name: 'AuthBloc');
      emit(AuthState.error(errorMessage: 'Error inesperado al cerrar sesión: $e'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    log(' AuthBloc: _userSubscription cancelada.', name: 'AuthBloc');
    return super.close();
  }
}