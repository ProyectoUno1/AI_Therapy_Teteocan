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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late StreamSubscription<dynamic> _userSubscription;
  StreamSubscription<DocumentSnapshot>? _patientDataSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required FirebaseFirestore firestore,
  }) : _authRepository = authRepository,
       _signInUseCase = signInUseCase,
       _registerUserUseCase = registerUserUseCase,
       _firestore = firestore,
       super(const AuthState.unknown()) {
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthRegisterPatientRequested>(_onAuthRegisterPatientRequested);
    on<AuthRegisterPsychologistRequested>(_onAuthRegisterPsychologistRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthStarted>(_onAuthStarted);
    on<UpdatePatientInfoRequested>(_onUpdatePatientInfoRequested);
    on<AuthStartListeningToPatient>(_onStartListeningToPatient);
    on<AuthStopListeningToPatient>(_onStopListeningToPatient);
    on<AuthPatientDataUpdated>(_onPatientDataUpdated);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthCheckEmailVerification>(_onCheckEmailVerification);
    on<AuthUpdateEmailRequested>(_onAuthUpdateEmailRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthAcceptTermsAndConditions>(_onAcceptTermsAndConditions);

    log(
      ' AuthBloc: Inicializando _userSubscription para authStateChanges.',
      name: 'AuthBloc',
    );
    _userSubscription = _authRepository.authStateChanges.listen((userProfile) {
      log(
        ' AuthBloc Subscription: Recibido userProfile del repositorio: ${userProfile?.runtimeType}',
        name: 'AuthBloc',
      );

      if (userProfile == null) {
        log(
          ' AuthBloc Subscription: Firebase User es null. Añadiendo AuthStatusChanged para UNATHENTICATED.',
          name: 'AuthBloc',
        );
        add(
          const AuthStatusChanged(
            AuthStatus.unauthenticated,
            null,
            userRole: UserRole.unknown,
          ),
        );
      } else if (userProfile is PatientModel) {
        log(
          ' AuthBloc Subscription: userProfile es PatientModel. Añadiendo AuthStatusChanged para AUTHENTICATED (Patient).',
          name: 'AuthBloc',
        );
        add(
          AuthStatusChanged(
            AuthStatus.authenticated,
            userProfile,
            userRole: UserRole.patient,
          ),
        );
      } else if (userProfile is PsychologistModel) {
        log(
          ' AuthBloc Subscription: userProfile es PsychologistModel. Añadiendo AuthStatusChanged para AUTHENTICATED (Psychologist).',
          name: 'AuthBloc',
        );
        add(
          AuthStatusChanged(
            AuthStatus.authenticated,
            userProfile,
            userRole: UserRole.psychologist,
          ),
        );
      } else {
        log(
          ' AuthBloc Subscription: userProfile es de tipo inesperado: ${userProfile.runtimeType}. Forzando cierre de sesión.',
          name: 'AuthBloc',
        );
        add(
          const AuthStatusChanged(
            AuthStatus.unauthenticated,
            null,
            userRole: UserRole.unknown,
            errorMessage: 'Perfil de usuario inesperado. Sesión cerrada.',
          ),
        );
        _authRepository.signOut();
      }
    });
  }

  void _onStartListeningToPatient(
    AuthStartListeningToPatient event,
    Emitter<AuthState> emit,
  ) {
    log('AuthBloc: Iniciando escucha de datos del paciente: ${event.userId}', name: 'AuthBloc');
    
    // Cancelar suscripción anterior si existe
    _patientDataSubscription?.cancel();
  
    _patientDataSubscription = _firestore
        .collection('patients')
        .doc(event.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        try {
          final patient = PatientModel.fromFirestore(snapshot, null);
          add(AuthPatientDataUpdated(patient));
          log('AuthBloc: Datos del paciente actualizados: ${patient.messageCount} mensajes usados', name: 'AuthBloc');
        } catch (e) {
          log('AuthBloc: Error parsing patient data: $e', name: 'AuthBloc');
        }
      }
    }, onError: (error) {
      log('AuthBloc: Error listening to patient data: $error', name: 'AuthBloc');
    });
  }

  void _onStopListeningToPatient(
    AuthStopListeningToPatient event,
    Emitter<AuthState> emit,
  ) {
    log('AuthBloc: Deteniendo escucha de datos del paciente', name: 'AuthBloc');
    _patientDataSubscription?.cancel();
    _patientDataSubscription = null;
  }

  void _onPatientDataUpdated(
    AuthPatientDataUpdated event,
    Emitter<AuthState> emit,
  ) {
    log('AuthBloc: Actualizando estado con nuevos datos del paciente', name: 'AuthBloc');
    
    if (state.isAuthenticatedPatient && state.patient?.uid == event.patient.uid) {
      emit(state.copyWith(
        patient: event.patient,
      ));
      log('AuthBloc: Estado actualizado con nuevos datos del paciente', name: 'AuthBloc');
    }
  }

  Future<void> _onAuthStarted(
  AuthStarted event,
  Emitter<AuthState> emit,
) async {
  log(
    ' AuthBloc Event: AuthStarted recibido. Verificando estado de autenticación...',
    name: 'AuthBloc',
  );

  try {
    emit(const AuthState.loading());

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      log(
        ' AuthBloc: Usuario autenticado encontrado: ${currentUser.uid}',
        name: 'AuthBloc',
      );

      final userDoc = await _firestore
          .collection('patients')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userRole = userData['role'] as String?;

        if (userRole == 'patient') {
          final patient = PatientModel.fromFirestore(userDoc, null);
          emit(
            AuthState.authenticated(
              userRole: UserRole.patient,
              patient: patient,
            ),
          );
          
          add(AuthStartListeningToPatient(patient.uid));
        } else if (userRole == 'psychologist') {
          
          final psychologistDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (psychologistDoc.exists) {
            final psychologistData = psychologistDoc.data()!;
            final psychologist = PsychologistModel.fromFirestore(psychologistData);
            emit(
              AuthState.authenticated(
                userRole: UserRole.psychologist,
                psychologist: psychologist,
              ),
            );
          } else {
            emit(const AuthState.unauthenticated());
          }
        } else {
          emit(const AuthState.unauthenticated());
        }
      } else {
        emit(const AuthState.unauthenticated());
      }
    } else {
      log(' AuthBloc: No hay usuario autenticado.', name: 'AuthBloc');
      emit(const AuthState.unauthenticated());
    }
  } catch (e) {
    log(' AuthBloc: Error verificando autenticación: $e', name: 'AuthBloc');
    emit(
      const AuthState.error(errorMessage: 'Error verificando autenticación'),
    );
  }
}

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    log(
      'DEBUG AUTHBLOC: Inicia procesamiento de _onAuthStatusChanged para evento: ${event.status}',
      name: 'AuthBloc',
    );
    log(
      ' AuthBloc Event: AuthStatusChanged recibido. Nuevo estado: ${event.status}, Rol: ${event.userRole}, Perfil: ${event.userProfile?.runtimeType}, Mensaje Error: ${event.errorMessage}',
      name: 'AuthBloc',
    );

    _patientDataSubscription?.cancel();
    _patientDataSubscription = null;

    AuthState newState;

    switch (event.status) {
      case AuthStatus.authenticated:
        if (event.userRole == UserRole.patient &&
            event.userProfile is PatientModel) {
          final patient = event.userProfile as PatientModel;
          newState = AuthState.authenticated(
            userRole: UserRole.patient,
            patient: patient,
          );
          
         
          add(AuthStartListeningToPatient(patient.uid));
          
        } else if (event.userRole == UserRole.psychologist &&
            event.userProfile is PsychologistModel) {
          newState = AuthState.authenticated(
            userRole: UserRole.psychologist,
            psychologist: event.userProfile as PsychologistModel,
          );
        } else {
          log(
            ' AuthBloc Event: AuthStatusChanged (authenticated) con rol/perfil inconsistente. Forzando unauthenticated.',
            name: 'AuthBloc',
          );
          newState = AuthState.unauthenticated(
            errorMessage:
                event.errorMessage ??
                'Rol o perfil inconsistente. Sesión cerrada.',
          );
          _authRepository.signOut();
        }
        break;
      case AuthStatus.unauthenticated:
        
        add(const AuthStopListeningToPatient());
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
      log(
        ' AuthBloc Emitió: Nuevo estado: ${newState.status}. Detalle: ${newState.userRole}, Patient: ${newState.patient != null}, Psychologist: ${newState.psychologist != null}, Error: ${newState.errorMessage}',
        name: 'AuthBloc',
      );
    } else {
      log(
        ' AuthBloc NO EMITIÓ: Nuevo estado es idéntico al actual (${newState.status}). Equatable funcionó.',
        name: 'AuthBloc',
      );
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
        emit(
          const AuthState.success(
            errorMessage: 'Perfil actualizado exitosamente.',
          ),
        );
        emit(
          AuthState.authenticated(
            userRole: UserRole.patient,
            patient: updatedPatient,
          ),
        );
      } on AppException catch (e) {
        emit(AuthState.error(errorMessage: e.message));
      } catch (e) {
        emit(
          const AuthState.error(
            errorMessage:
                'Ocurrió un error inesperado al actualizar el perfil.',
          ),
        );
      }
    } else {
      emit(
        const AuthState.error(
          errorMessage: 'No tienes permiso para actualizar este perfil.',
        ),
      );
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    log(
      ' AuthBloc Event: AuthSignInRequested para ${event.email}',
      name: 'AuthBloc',
    );
    emit(const AuthState.loading());

    try {
      await _signInUseCase(email: event.email, password: event.password);
      log(
        ' AuthBloc Event: SignInUseCase completado. Esperando emisión de authStateChanges.',
        name: 'AuthBloc',
      );
    } on AppException catch (e) {
      log(
        ' AuthBloc Event: Error de AppException al iniciar sesión: ${e.message}',
        name: 'AuthBloc',
      );
      emit(AuthState.error(errorMessage: e.message));
    } catch (e) {
      log(
        ' AuthBloc Event: Error inesperado al iniciar sesión: $e',
        name: 'AuthBloc',
      );
      emit(
        AuthState.error(errorMessage: 'Error inesperado al iniciar sesión: $e'),
      );
    }
  }

  Future<void> _onAuthRegisterPatientRequested(
  AuthRegisterPatientRequested event,
  Emitter<AuthState> emit,
) async {
  log('AuthBloc Event: AuthRegisterPatientRequested para ${event.email}', name: 'AuthBloc');
  emit(const AuthState.loading());

  try {
    // 1. Registrar paciente
    await _authRepository.registerPatient(
      email: event.email,
      password: event.password,
      username: event.username,
      phoneNumber: event.phoneNumber,
      dateOfBirth: event.dateOfBirth,
    );

    log('AuthBloc: Registro exitoso, iniciando sesión automática para ${event.email}', name: 'AuthBloc');

    // 2. Iniciar sesión automáticamente
    await _signInUseCase(email: event.email, password: event.password);

    // 3.Enviar email de verificación
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      log('AuthBloc: Email de verificación enviado a ${event.email}', name: 'AuthBloc');
    }

    // 4. Emitir éxito
    emit(const AuthState.success(errorMessage: 'Registro exitoso'));
    
  } on AppException catch (e) {
    log('AuthBloc: Error de AppException al registrar paciente: ${e.message}', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: e.message));
  } catch (e) {
    log('AuthBloc: Error inesperado al registrar paciente: $e', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: 'Error inesperado al registrar paciente: $e'));
  }
}

  Future<void> _onAuthRegisterPsychologistRequested(
  AuthRegisterPsychologistRequested event,
  Emitter<AuthState> emit,
) async {
  log('AuthBloc: Iniciando registro de psicólogo para ${event.email}', name: 'AuthBloc');
  emit(const AuthState.loading());

  try {
    // Paso 1: Registrar psicólogo 
    final psychologist = await _authRepository.registerPsychologist(
      email: event.email,
      password: event.password,
      username: event.username,
      phoneNumber: event.phoneNumber,
      professionalLicense: event.professionalLicense,
      dateOfBirth: event.dateOfBirth,
    );
    
    log('AuthBloc: Psicólogo registrado en Firestore: ${psychologist.uid}', name: 'AuthBloc');

    // Paso 2: Iniciar sesión automáticamente
    await _signInUseCase(email: event.email, password: event.password);
    log('AuthBloc: Sesión iniciada automáticamente para ${event.email}', name: 'AuthBloc');

    // Paso 3: Enviar email de verificación
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      log('AuthBloc: Email de verificación enviado a ${event.email}', name: 'AuthBloc');
    }

    // Paso 4: Emitir éxito (esto dispara la navegación)
    emit(const AuthState.success(
      errorMessage: 'Registro completado exitosamente.',
    ));
    
  } on AppException catch (e) {
    log('AuthBloc: Error AppException al registrar: ${e.message}', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: e.message));
  } catch (e) {
    log('AuthBloc: Error inesperado al registrar: $e', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: 'Error inesperado: $e'));
  }
}

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    log(' AuthBloc Event: AuthSignOutRequested recibido.', name: 'AuthBloc');
    emit(const AuthState.loading());
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        log(
          'AuthBloc: Actualizando estado offline de usuario ${currentUser.uid} antes de cerrar sesión.',
          name: 'AuthBloc',
        );
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'isOnline': false,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      await _authRepository.signOut();
      log(
        ' AuthBloc Event: SignOut completado. Esperando emisión de authStateChanges (unauthenticated).',
        name: 'AuthBloc',
      );
    } on AppException catch (e) {
      log(
        ' AuthBloc Event: Error de AppException al cerrar sesión: ${e.message}',
        name: 'AuthBloc',
      );
      emit(AuthState.error(errorMessage: e.message));
    } catch (e) {
      log(
        ' AuthBloc Event: Error inesperado al cerrar sesión: $e',
        name: 'AuthBloc',
      );
      emit(
        AuthState.error(errorMessage: 'Error inesperado al cerrar sesión: $e'),
      );
    }
  }

  Future<void> _onAuthPasswordResetRequested(
  AuthPasswordResetRequested event,
  Emitter<AuthState> emit,
) async {
  log(
    'AuthBloc Event: AuthPasswordResetRequested para ${event.email}',
    name: 'AuthBloc',
  );
  emit(const AuthState.loading());

  try {
    await _authRepository.sendPasswordResetEmail(email: event.email);
    log(
      'AuthBloc: Correo de recuperación enviado exitosamente a ${event.email}',
      name: 'AuthBloc',
    );
    emit(
      const AuthState.success(
        errorMessage: 'Hemos enviado un correo con instrucciones para recuperar tu contraseña. Revisa tu bandeja de entrada.',
      ),
    );
  } on AppException catch (e) {
    log(
      'AuthBloc: Error de AppException al enviar correo de recuperación: ${e.message}',
      name: 'AuthBloc',
    );
    emit(AuthState.error(errorMessage: e.message));
  } catch (e) {
    log(
      'AuthBloc: Error inesperado al enviar correo de recuperación: $e',
      name: 'AuthBloc',
    );
    emit(
      AuthState.error(
        errorMessage: 'Error inesperado al enviar correo de recuperación: $e',
      ),
    );
  }
}


Future<void> _onCheckEmailVerification(
  AuthCheckEmailVerification event,
  Emitter<AuthState> emit,
) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    await currentUser?.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      // Intentar cargar como psicólogo primero
      final psychologistDoc = await _firestore
          .collection('psychologists')
          .doc(refreshedUser.uid)
          .get();
      
      if (psychologistDoc.exists) {
        final psychologist = PsychologistModel.fromFirestore(psychologistDoc.data()!);
        emit(AuthState.authenticated(
          userRole: UserRole.psychologist,
          psychologist: psychologist,
        ));
        return;
      };
      final patientDoc = await _firestore
          .collection('patients')
          .doc(refreshedUser.uid)
          .get();
      
      if (patientDoc.exists) {
        final patient = PatientModel.fromFirestore(patientDoc, null);
        emit(AuthState.authenticated(
          userRole: UserRole.patient,
          patient: patient,
        ));
        
        // Iniciar escucha de datos del paciente
        add(AuthStartListeningToPatient(patient.uid));
        return;
      }
      emit(const AuthState.error(
        errorMessage: 'No se encontró tu perfil. Por favor contacta soporte.',
      ));
      
    } else {
      log('AuthBloc: Email aún no verificado', name: 'AuthBloc');
    }
  } catch (e) {
    emit(AuthState.error(
      errorMessage: 'Error al verificar: $e',
    ));
  }
}

Future<void> _onAuthUpdateEmailRequested(
  AuthUpdateEmailRequested event,
  Emitter<AuthState> emit,
) async {
  log('AuthBloc: Actualizando email a ${event.newEmail}', name: 'AuthBloc');
  emit(const AuthState.loading());

  try {
    await _authRepository.updateEmail(newEmail: event.newEmail);
    log('AuthBloc: Email actualizado exitosamente', name: 'AuthBloc');
    emit(const AuthState.success(
      errorMessage: 'Hemos enviado un correo de verificación a tu nuevo email.',
    ));
    
    // Cerrar sesión para que vuelva a iniciar con el nuevo email
    await Future.delayed(const Duration(seconds: 2));
    add(const AuthSignOutRequested());
  } on AppException catch (e) {
    log('AuthBloc: Error al actualizar email: ${e.message}', name: 'AuthBloc');
    emit(AuthState.error(errorMessage: e.message));
  } catch (e) {
    log('AuthBloc: Error inesperado al actualizar email: $e', name: 'AuthBloc');
    emit(AuthState.error(
      errorMessage: 'Error inesperado al actualizar email: $e',
    ));
  }
}

Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Recargar los datos del psicólogo desde Firestore
    final psychologistDoc = await FirebaseFirestore.instance
        .collection('psychologists')
        .doc(user.uid)
        .get();
    
    if (psychologistDoc.exists) {
      final psychologist = PsychologistModel.fromFirestore(
        psychologistDoc.data()!
      );
      emit(AuthState.authenticated(
        userRole: UserRole.psychologist,
        psychologist: psychologist,
      ));
    }
  }
}

Future<void> _onAcceptTermsAndConditions(
  AuthAcceptTermsAndConditions event,
  Emitter<AuthState> emit,
) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      log('AuthBloc: No hay usuario autenticado para aceptar términos', name: 'AuthBloc');
      return;
    }

    log('AuthBloc: Aceptando términos para ${event.userRole}', name: 'AuthBloc');

    final token = await user.getIdToken();
    
    // Construir la URL correcta según el tipo de usuario
    final String endpoint = event.userRole == 'patient' 
        ? '/patients/accept-terms'
        : '/psychologists/accept-terms';

    log('AuthBloc: Llamando a endpoint: $endpoint', name: 'AuthBloc');

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      log('AuthBloc: Términos aceptados exitosamente en el backend', name: 'AuthBloc');
      
      // Actualizar el estado local
      if (event.userRole == 'patient' && state.patient != null) {
        emit(state.copyWith(
          patient: state.patient!.copyWith(termsAccepted: true),
        ));
      } else if (event.userRole == 'psychologist' && state.psychologist != null) {
        emit(state.copyWith(
          psychologist: state.psychologist!.copyWith(termsAccepted: true),
        ));
      }
      
      log('AuthBloc: Estado actualizado con termsAccepted: true', name: 'AuthBloc');
    } else {
      log('AuthBloc: Error del servidor: ${response.statusCode} - ${response.body}', name: 'AuthBloc');
      throw Exception('Error al actualizar términos: ${response.statusCode}');
    }
  } catch (e) {
    log('AuthBloc: Error al aceptar términos: $e', name: 'AuthBloc');
    emit(AuthState.error(
      errorMessage: 'Error al aceptar términos: $e',
    ));
  }
}

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _patientDataSubscription?.cancel();
    log(' AuthBloc: Todas las suscripciones canceladas.', name: 'AuthBloc');
    return super.close();
  }
  
}