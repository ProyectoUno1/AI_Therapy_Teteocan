// lib/presentation/auth/bloc/auth_event.dart
abstract class AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final String? firebaseUid;
  final String? userRole;
  final String? userName;

  AuthUserChanged({this.firebaseUid, this.userRole, this.userName});
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterPatientRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String phoneNumber;
  final DateTime dateOfBirth;  

  AuthRegisterPatientRequested({
    required this.email,
    required this.password,
    required this.username,
    required this.phoneNumber,
    required this.dateOfBirth,  
  });
}

class AuthRegisterPsychologistRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String phoneNumber;
  final String professionalLicense;
  final String? specialty;
  final String? schedule;
  final String? aboutMe;
  final DateTime dateOfBirth;

  AuthRegisterPsychologistRequested({
    required this.email,
    required this.password,
    required this.username,
    required this.phoneNumber,
    required this.professionalLicense,
    this.specialty,
    this.schedule,
    this.aboutMe,
    required this.dateOfBirth,  
  });
}

class AuthLogoutRequested extends AuthEvent {}
