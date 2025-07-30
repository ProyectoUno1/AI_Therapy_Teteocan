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

  late StreamSubscription<dynamic?> _userSubscription;

 AuthBloc({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required RegisterUserUseCase registerUserUseCase,
  }) : _authRepository = authRepository,
       _signInUseCase = signInUseCase,
       _registerUserUseCase = registerUserUseCase,
       super(const AuthState()) {
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthRegisterPatientRequested>(_onAuthRegisterPatientRequested);
    on<AuthRegisterPsychologistRequested>(_onAuthRegisterPsychologistRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthStarted>(_onAuthStarted);

    log('🔵 AuthBloc: Inicializando _userSubscription para authStateChanges.', name: 'AuthBloc');
    _userSubscription = _authRepository.authStateChanges.listen((userProfile) {
      log('🔵 AuthBloc Subscription: Recibido userProfile del repositorio: ${userProfile?.runtimeType}', name: 'AuthBloc');

      if (userProfile == null) {
        log('🔵 AuthBloc Subscription: Firebase User es null. Añadiendo AuthStatusChanged.unauthenticated.', name: 'AuthBloc');
        add(
          const AuthStatusChanged(
            AuthStatus.unauthenticated,
            null,
            userRole: UserRole.unknown,
          ),
        );
      } else if (userProfile is PatientModel) {
        log('🔵 AuthBloc Subscription: userProfile es PatientModel. Añadiendo AuthStatusChanged.authenticated (Patient).', name: 'AuthBloc');
        add(
          AuthStatusChanged(
            AuthStatus.authenticated,
            userProfile,
            userRole: UserRole.patient,
          ),
        );
      } else if (userProfile is PsychologistModel) {
        log('🔵 AuthBloc Subscription: userProfile es PsychologistModel. Añadiendo AuthStatusChanged.authenticated (Psychologist).', name: 'AuthBloc');
        add(
          AuthStatusChanged(
            AuthStatus.authenticated,
            userProfile,
            userRole: UserRole.psychologist,
          ),
        );
      } else {
        log('🔴 AuthBloc Subscription: userProfile es de tipo inesperado: ${userProfile.runtimeType}', name: 'AuthBloc');
        add(
          const AuthStatusChanged(
            AuthStatus.unauthenticated,
            null,
            userRole: UserRole.unknown,
          ),
        );
        _authRepository.signOut();
      }
    });
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    log('🔵 AuthBloc Event: AuthStarted recibido.');
  }

void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
  log('🚨DEBUG AUTHBLOC: Inicia procesamiento de _onAuthStatusChanged para evento: ${event.status}');
  log('🔵 AuthBloc Event: AuthStatusChanged recibido. Nuevo estado: ${event.status}, Rol: ${event.userRole}, Perfil: ${event.userProfile?.runtimeType}');

  final AuthState currentState = state;
  final AuthState newState;

  if (event.status == AuthStatus.authenticated) {
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
      log(
        '🔴 AuthBloc Event: AuthStatusChanged (authenticated) con rol/perfil inconsistente. Forzando unauthenticated.',
      );
      newState = AuthState.unauthenticated(errorMessage: 'Rol o perfil inconsistente');
      _authRepository.signOut(); // Si el perfil es inconsistente, mejor cerrar sesión.
    }
  } else if (event.status == AuthStatus.unauthenticated) {
   
    newState = const AuthState.unauthenticated(); // Crea un nuevo estado sin error
  } else if (event.status == AuthStatus.loading) {
    newState = const AuthState.loading();
  } else if (event.status == AuthStatus.error) {
    newState = AuthState.error(errorMessage: event.errorMessage ?? state.errorMessage); 
  } else if (event.status == AuthStatus.success) {
    newState = AuthState.success(errorMessage: event.errorMessage ?? state.errorMessage); 
  } else {
    newState = const AuthState.unknown();
  }

  
  if (currentState != newState) {
    emit(newState);
    log(
      '✅ AuthBloc Emitió: ${newState.status}. Estado final: ${state.status}, isAuthPatient: ${state.isAuthenticatedPatient}, isAuthPsychologist: ${state.isAuthenticatedPsychologist}',
    );
  } else {
    log(
      '🟡 AuthBloc NO EMITIÓ: Nuevo estado es idéntico al actual (${newState.status}). Equatable funcionó.',
    );
  }
}
  Future<void> _onAuthSignInRequested(
  AuthSignInRequested event,
  Emitter<AuthState> emit,
) async {
  log('🔵 AuthBloc Event: AuthSignInRequested para ${event.email}');
  // Emite un estado de carga mientras se realiza el login
  emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

  try {
    await _signInUseCase(
      email: event.email,
      password: event.password,
    );
    
    log('🟢 AuthBloc Event: SignInUseCase completado. Esperando emisión de authStateChanges.');
  } on AppException catch (e) {
    log('🔴 AuthBloc Event: Error de AppException al iniciar sesión: ${e.message}');
    emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
  } catch (e) {
    log('🔴 AuthBloc Event: Error inesperado al iniciar sesión: $e');
    emit(state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al iniciar sesión: $e'));
  }
}

Future<void> _onAuthRegisterPatientRequested(
  AuthRegisterPatientRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState.loading());
  try {
    final patient = await _authRepository.registerPatient(
      email: event.email,
      password: event.password,
      username: event.username,
      phoneNumber: event.phoneNumber,
      dateOfBirth: event.dateOfBirth,
    );
    
    emit(const AuthState.success());
  } catch (e) {
    emit(AuthState.error(errorMessage: e.toString()));
  }
}

Future<void> _onAuthRegisterPsychologistRequested(
  AuthRegisterPsychologistRequested event,
  Emitter<AuthState> emit,
) async {
  log('🔵 AuthBloc Event: AuthRegisterPsychologistRequested para ${event.email}');
  emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
  try {
    await _registerUserUseCase.registerPsychologist(
      email: event.email,
      password: event.password,
      username: event.username,
      phoneNumber: event.phoneNumber,
      professionalLicense: event.professionalLicense,
      dateOfBirth: event.dateOfBirth,
    );
    await _authRepository.signOut();

    log('🟢 AuthBloc Event: Registro de paciente completado y deslogueo realizado.');
    emit(state.copyWith(status: AuthStatus.success, errorMessage: null));
  } on AppException catch (e) {
    log('🔴 AuthBloc Event: Error de AppException al registrar psicólogo: ${e.message}');
    emit(state.copyWith(status: AuthStatus.error, errorMessage: e.message));
  } catch (e) {
    log('🔴 AuthBloc Event: Error inesperado al registrar psicólogo: $e');
    emit(state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al registrar psicólogo: $e'));
  }
}


  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final loadingState = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );
    emit(loadingState);
    try {
      await _authRepository.signOut();
      log(
        '🟢 AuthBloc Event: SignOut completado. Esperando emisión de authStateChanges (unauthenticated).',
      );
    } on AppException catch (e) {
      log(
        '🔴 AuthBloc Event: Error de AppException al cerrar sesión: ${e.message}',
      );
      final errorState = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      emit(errorState);
    } catch (e) {
      log('🔴 AuthBloc Event: Error inesperado al cerrar sesión: $e');
      final errorState = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error inesperado al cerrar sesión: $e',
      );
      emit(errorState);
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
