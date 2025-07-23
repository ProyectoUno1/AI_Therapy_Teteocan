// lib/core/utils/input_validators.dart
class InputValidators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Por favor ingresa un email válido.';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'El nombre de usuario es obligatorio.';
    }
    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'El número de teléfono es obligatorio.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone) || phone.length < 7) {
      return 'Ingresa un número de teléfono válido.';
    }
    return null;
  }

  static String? validateProfessionalId(String? id) {
    if (id == null || id.isEmpty) {
      return 'La cédula profesional es obligatoria.';
    }
    // Ejemplo de validación: solo números, entre 7 y 10 dígitos
    if (!RegExp(r'^[0-9]{7,10}$').hasMatch(id)) {
      return 'Cédula profesional inválida (solo números, 7-10 dígitos).';
    }
    return null;
  }
}
