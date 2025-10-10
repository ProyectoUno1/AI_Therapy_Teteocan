// lib/data/datasources/auth_remote_datasource.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<fb_auth.UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<fb_auth.UserCredential> register({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Stream<fb_auth.User?> get authStateChanges;

  Future<void> sendPasswordResetEmail({required String email});
  Future<void> updateEmail({required String newEmail});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl({fb_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  @override
  Future<fb_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FetchDataException(
        'Ocurrió un error inesperado al iniciar sesión: $e',
      );
    }
  }

  @override
  Future<fb_auth.UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FetchDataException('Ocurrió un error inesperado al registrar: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw FetchDataException('Error al cerrar sesión: $e');
    }
  }

  @override
  Stream<fb_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  AppException _handleFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return UserNotFoundException(
          'No se encontró un usuario con ese email.',
        );
      case 'wrong-password':
        return WrongPasswordException('Contraseña incorrecta.');
      case 'email-already-in-use':
        return EmailAlreadyInUseException(
          'La cuenta ya existe para ese email.',
        );
      case 'weak-password':
        return WeakPasswordException('La contraseña es demasiado débil.');
      case 'invalid-email':
        return InvalidInputException('El formato del email es inválido.');
      case 'network-request-failed':
        return FetchDataException(
          'Error de red. Por favor, verifica tu conexión.',
        );
      default:
        return AppException(
          'Error de autenticación: ${e.message ?? 'Desconocido'}',
        );
    }
  }

  @override
Future<void> sendPasswordResetEmail({required String email}) async {
  try {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  } on fb_auth.FirebaseAuthException catch (e) {
    throw _handleFirebaseAuthException(e);
  } catch (e) {
    throw FetchDataException(
      'Ocurrió un error inesperado al enviar el correo de recuperación: $e',
    );
  }
}

@override
Future<void> sendEmailVerification() async {
  try {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  } catch (e) {
    throw FetchDataException('Error al enviar correo de verificación: $e');
  }
}
@override
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
      } else {
        throw AuthException('No hay usuario autenticado');
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw FetchDataException(
        'Ocurrió un error inesperado al actualizar el email: $e',
      );
    }
  }
}
