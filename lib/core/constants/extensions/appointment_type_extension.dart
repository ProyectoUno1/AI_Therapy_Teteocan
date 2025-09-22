// lib/core/extensions/appointment_type_extension.dart

import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

extension AppointmentTypeExtension on AppointmentType {
  String get displayName {
    switch (this) {
      case AppointmentType.online:
        return 'En línea';
      case AppointmentType.inPerson:
        return 'Presencial';
    }
  }

  String get description {
    switch (this) {
      case AppointmentType.online:
        return 'Sesión por videoconferencia';
      case AppointmentType.inPerson:
        return 'Sesión en consultorio';
    }
  }
}