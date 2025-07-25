// lib/core/exceptions/app_exceptions.dart
class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() {
    return '$prefix: $message';
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
    : super(
        message ?? 'Error durante la comunicación con el servidor',
        'Error de Conexión',
      );
}

class BadRequestException extends AppException {
  BadRequestException([String? message])
    : super(message ?? 'Solicitud inválida', 'Solicitud Inválida');
}

class UnauthorisedException extends AppException {
  UnauthorisedException([String? message])
    : super(message ?? 'No autorizado', 'No Autorizado');
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message])
    : super(message ?? 'Entrada inválida', 'Entrada Inválida');
}

class UserNotFoundException extends AppException {
  UserNotFoundException([String? message])
    : super(message ?? 'Usuario no encontrado', 'Usuario no Encontrado');
}

class WrongPasswordException extends AppException {
  WrongPasswordException([String? message])
    : super(message ?? 'Contraseña incorrecta', 'Contraseña Incorrecta');
}

class EmailAlreadyInUseException extends AppException {
  EmailAlreadyInUseException([String? message])
    : super(message ?? 'El email ya está en uso', 'Email en Uso');
}

class WeakPasswordException extends AppException {
  WeakPasswordException([String? message])
    : super(message ?? 'La contraseña es demasiado débil', 'Contraseña Débil');
}

class RoleNotFoundException extends AppException {
  RoleNotFoundException([String? message])
    : super(message ?? 'Rol de usuario no definido', 'Rol no Encontrado');
}
class CreateDataException extends AppException {
  CreateDataException(String message) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}