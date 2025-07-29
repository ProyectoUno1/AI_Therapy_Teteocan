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
  })  : _authRepository = authRepository,
        _signInUseCase = signInUseCase,
        _registerUserUseCase = registerUserUseCase,
        super(const AuthState()) {
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthRegisterPatientRequested>(_onAuthRegisterPatientRequested);
    on<AuthRegisterPsychologistRequested>(_onAuthRegisterPsychologistRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthStarted>(_onAuthStarted);

    _userSubscription = _authRepository.authStateChanges.listen((userProfile) {
      if (userProfile == null) {
        add(const AuthStatusChanged(AuthStatus.unauthenticated, null, userRole: UserRole.unknown));
      } else if (userProfile is PatientModel) {
        add(AuthStatusChanged(AuthStatus.authenticated, userProfile, userRole: UserRole.patient));
      } else if (userProfile is PsychologistModel) {
        add(AuthStatusChanged(AuthStatus.authenticated, userProfile, userRole: UserRole.psychologist));
      } else {
        log('🔴 AuthBloc Subscription: userProfile es de tipo inesperado: ${userProfile.runtimeType}');
        add(const AuthStatusChanged(AuthStatus.unauthenticated, null, userRole: UserRole.unknown));
        _authRepository.signOut();
      }
    });
  }

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    log('🔵 AuthBloc Event: AuthStarted recibido.');
  }

  
  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    

    if (event.status == AuthStatus.authenticated) {
      if (event.userRole == UserRole.patient && event.userProfile is PatientModel) {
        final newState = state.copyWith(
          status: AuthStatus.authenticated,
          userRole: UserRole.patient,
          patient: event.userProfile as PatientModel,
          psychologist: null, 
          errorMessage: null,
        );
       
        emit(newState);
        log('✅ AuthBloc Emitió: AuthStatus.authenticated como PACIENTE. Estado actual: ${state.status}, isAuthPatient: ${state.isAuthenticatedPatient}');
      } else if (event.userRole == UserRole.psychologist && event.userProfile is PsychologistModel) {
        final newState = state.copyWith(
          status: AuthStatus.authenticated,
          userRole: UserRole.psychologist,
          psychologist: event.userProfile as PsychologistModel,
          patient: null, 
          errorMessage: null,
        );
        emit(newState);
        log('✅ AuthBloc Emitió: AuthStatus.authenticated como PSICÓLOGO. Estado actual: ${state.status}, isAuthPsy: ${state.isAuthenticatedPsychologist}');
      } else {
        log('🔴 AuthBloc Event: AuthStatusChanged (authenticated) con rol/perfil inconsistente.');
        final newState = state.copyWith(
          status: AuthStatus.unauthenticated,
          userRole: UserRole.unknown,
          patient: null,
          psychologist: null,
          errorMessage: 'Inconsistencia en perfil de usuario autenticado.',
        );
        emit(newState);
        _authRepository.signOut();
      }
    } else if (event.status == AuthStatus.unauthenticated) {
      final newState = state.copyWith(
        status: AuthStatus.unauthenticated,
        userRole: UserRole.unknown,
        patient: null,
        psychologist: null,
        errorMessage: null,
      );
      emit(newState);
      log('🔵 AuthBloc Event: AuthStatusChanged - Estado FINAL emitido: ${state.status}, isAuthPatient: ${state.isAuthenticatedPatient}, isAuthPsy: ${state.isAuthenticatedPsychologist}');
    } else {
      final newState = state.copyWith(
        status: event.status,
        errorMessage: state.errorMessage,
      );
      emit(newState);
      log('🔵 AuthBloc Event: AuthStatusChanged - Estado NO FINAL ${event.status} emitido.');
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    log('🔵 AuthBloc Event: AuthSignInRequested para ${event.email}');
    final loadingState = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    emit(loadingState);

    try {
      await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      log('🟢 AuthBloc Event: SignInUseCase completado. Esperando emisión de authStateChanges.');
    } on AppException catch (e) {
      log('🔴 AuthBloc Event: Error de AppException al iniciar sesión: ${e.message}');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      emit(errorState);
    } catch (e) {
      log('🔴 AuthBloc Event: Error inesperado al iniciar sesión: $e');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al iniciar sesión: $e');
      emit(errorState);
    }
  }

  Future<void> _onAuthRegisterPatientRequested(
    AuthRegisterPatientRequested event,
    Emitter<AuthState> emit,
  ) async {
    final loadingState = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    emit(loadingState);
    try {
      await _registerUserUseCase.registerPatient(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        dateOfBirth: event.dateOfBirth,
      );
      log('🟢 AuthBloc Event: Registro de paciente completado. Emitiendo AuthStatus.success.');
      final successState = state.copyWith(status: AuthStatus.success, errorMessage: null);
      emit(successState);
    } on AppException catch (e) {
      log('🔴 AuthBloc Event: Error de AppException al registrar paciente: ${e.message}');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      emit(errorState);
    } catch (e) {
      log('🔴 AuthBloc Event: Error inesperado al registrar paciente: $e');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al registrar paciente: $e');
      emit(errorState);
    }
  }

  Future<void> _onAuthRegisterPsychologistRequested(
    AuthRegisterPsychologistRequested event,
    Emitter<AuthState> emit,
  ) async {
    final loadingState = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    emit(loadingState);
    try {
      await _registerUserUseCase.registerPsychologist(
        email: event.email,
        password: event.password,
        username: event.username,
        phoneNumber: event.phoneNumber,
        professionalLicense: event.professionalLicense,
        dateOfBirth: event.dateOfBirth,
      );
      log('🟢 AuthBloc Event: Registro de psicólogo completado. Emitiendo AuthStatus.success.');
      final successState = state.copyWith(status: AuthStatus.success, errorMessage: null);
      emit(successState);
    } on AppException catch (e) {
      log('🔴 AuthBloc Event: Error de AppException al registrar psicólogo: ${e.message}');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      emit(errorState);
    } catch (e) {
      log('🔴 AuthBloc Event: Error inesperado al registrar psicólogo: $e');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al registrar psicólogo: $e');
      emit(errorState);
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final loadingState = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    emit(loadingState);
    try {
      await _authRepository.signOut();
      log('🟢 AuthBloc Event: SignOut completado. Esperando emisión de authStateChanges (unauthenticated).');
    } on AppException catch (e) {
      log('🔴 AuthBloc Event: Error de AppException al cerrar sesión: ${e.message}');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      emit(errorState);
    } catch (e) {
      log('🔴 AuthBloc Event: Error inesperado al cerrar sesión: $e');
      final errorState = state.copyWith(status: AuthStatus.error, errorMessage: 'Error inesperado al cerrar sesión: $e');
      emit(errorState);
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}