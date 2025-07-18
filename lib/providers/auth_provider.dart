import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    // Escuchar cambios en el estado de autenticación
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false; // Asegurarse de que loading sea false cuando hay cambios
      notifyListeners();
    });
  }
  
  // Registrar usuario
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      AuthResult result = await _authService.registerWithEmailAndPassword(
        email, 
        password, 
        name
      );
      
      if (result.success) {
        _user = result.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Iniciar sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      AuthResult result = await _authService.signInWithEmailAndPassword(
        email, 
        password
      );
      
      if (result.success) {
        _user = result.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Iniciar sesión con Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      AuthResult result = await _authService.signInWithGoogle();
      
      if (result.success) {
        _user = result.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _user = null;
    _setLoading(false);
    notifyListeners();
  }
  
  // Obtener token actual
  Future<String?> getCurrentToken() async {
    if (_user != null) {
      return await _user!.getIdToken();
    }
    return null;
  }
  
  // Renovar token
  Future<String?> refreshToken() async {
    return await _authService.refreshToken();
  }
  
  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  // Método para obtener información del usuario
  String get userName {
    if (_user != null) {
      return _user!.displayName ?? 
             _user!.email?.split('@')[0] ?? 
             'Usuario';
    }
    return 'Usuario';
  }
  
  String get userEmail {
    return _user?.email ?? '';
  }
  
  String get userId {
    return _user?.uid ?? '';
  }
}
