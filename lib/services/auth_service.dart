import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  
  // URL de tu backend - ajusta según tu configuración
  static const String _baseUrl = 'http://10.0.2.2:3000/api';
  
  AuthService() {
    // Configurar Google Sign-In
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      // Para testing en emulator, usar una configuración básica
    );
  }
  
  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Registrar usuario con email y contraseña
  Future<AuthResult> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name
  ) async {
    try {
      // Validar entrada
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Todos los campos son requeridos'
        );
      }
      
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el perfil del usuario con el nombre
      await userCredential.user?.updateDisplayName(name);
      
      // Obtener el token de Firebase
      String? idToken = await userCredential.user?.getIdToken();
      
      // Enviar datos al backend
      if (idToken != null) {
        await _sendUserDataToBackend(
          userCredential.user!.uid, 
          name, 
          email, 
          idToken
        );
      }
      
      return AuthResult(
        success: true, 
        user: userCredential.user,
        message: 'Registro exitoso'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code)
      );
    } catch (e) {
      // Manejo específico para errores de registro
      String errorMessage = 'Error de registro: ';
      if (e.toString().contains('network')) {
        errorMessage += 'Error de conexión. Verifica tu internet.';
      } else if (e.toString().contains('unknown')) {
        errorMessage += 'Error de configuración. Verifica que Firebase esté correctamente configurado.';
      } else {
        errorMessage += e.toString();
      }
      
      return AuthResult(
        success: false,
        message: errorMessage
      );
    }
  }
  
  // Iniciar sesión con email y contraseña
  Future<AuthResult> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Obtener y guardar el token
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await _saveTokenLocally(idToken);
      }
      
      return AuthResult(
        success: true, 
        user: userCredential.user,
        message: 'Inicio de sesión exitoso'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code)
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error inesperado: $e'
      );
    }
  }
  
  // Iniciar sesión con Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Cerrar sesión anterior de Google si existe
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(
          success: false,
          message: 'Inicio de sesión con Google cancelado'
        );
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Obtener el token de Firebase
      String? idToken = await userCredential.user?.getIdToken();
      
      // Enviar datos al backend si es un usuario nuevo
      if (idToken != null) {
        await _sendUserDataToBackend(
          userCredential.user!.uid,
          userCredential.user!.displayName ?? 'Usuario',
          userCredential.user!.email ?? '',
          idToken
        );
        await _saveTokenLocally(idToken);
      }
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Inicio de sesión con Google exitoso'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: 'Error Firebase: ${_getFirebaseErrorMessage(e.code)}'
      );
    } catch (e) {
      // Manejo específico para errores de Google Sign-In
      String errorMessage = 'Error al iniciar sesión con Google: ';
      if (e.toString().contains('ApiException')) {
        errorMessage += 'Error de configuración de Google Sign-In. ';
        if (e.toString().contains('10:')) {
          errorMessage += 'Problema con la configuración del proyecto (SHA-1).';
        }
      } else if (e.toString().contains('network')) {
        errorMessage += 'Error de conexión a internet.';
      } else {
        errorMessage += e.toString();
      }
      
      return AuthResult(
        success: false,
        message: errorMessage
      );
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _clearTokenLocally();
  }
  
  // Enviar datos del usuario al backend
  Future<void> _sendUserDataToBackend(
    String uid, 
    String name, 
    String email, 
    String idToken
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'uid': uid,
          'name': name,
          'email': email,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Usuario sincronizado con backend exitosamente');
      } else {
        print('❌ Error al sincronizar usuario con backend: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al comunicarse con el backend: $e');
    }
  }
  
  // Guardar token localmente
  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_token', token);
  }
  
  // Limpiar token local
  Future<void> _clearTokenLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firebase_token');
  }
  
  // Obtener token local
  Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_token');
  }
  
  // Renovar token si es necesario
  Future<String?> refreshToken() async {
    try {
      String? token = await currentUser?.getIdToken(true);
      if (token != null) {
        await _saveTokenLocally(token);
      }
      return token;
    } catch (e) {
      print('Error al renovar token: $e');
      return null;
    }
  }
  
  // Obtener mensajes de error más amigables
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email.';
      case 'user-not-found':
        return 'No se encontró un usuario con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error de autenticación: $code';
    }
  }
}

// Clase para manejar resultados de autenticación
class AuthResult {
  final bool success;
  final User? user;
  final String message;
  
  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}
