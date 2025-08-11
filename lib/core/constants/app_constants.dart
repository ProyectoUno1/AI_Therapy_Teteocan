// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Aurora AI Therapy App';

  // Colores de la paleta
  static const Color primaryColor = Color(0xFF3B716F);
  static const Color accentColor = Color(0xFF5CA0AC);
  static const Color lightAccentColor = Color(0xFF82C4C3);
  static const Color warningColor = Color(
    0xFFFFF9C4,
  ); // Amarillo para suscripción
  static const Color errorColor = Color(0xFFE57373); // Rojo para errores

   // NEW: Define these colors for the psychologist UI
  static const Color secondaryColor = Color(0xFF00A389); // A greenish/teal color, as seen in your psychologist images
  static const Color lightSecondaryColor = Color(0xFF66D9EF); // A lighter blue/green, if you need a lighter shade
  static const Color lightGreyBackground = Color(0xFFF5F5F5); // A very light grey often used for screen/card backgrounds
  static const Color lightGrayColor = Color(0xFFF0F0F0);


  // Rutas de imágenes
  static const String logoAuroraPath = 'assets/images/LogoAurora.png';

  // Duraciones de animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);

  // URLs del backend (¡Actualiza esto con tu IP/dominio real!)
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // Para emulador de Android
  // static const String baseUrl = 'http://localhost:3000/api'; // Para iOS Simulator o Web
  // static const String baseUrl = 'http://YOUR_LOCAL_IP:3000/api'; // Para dispositivo físico
}
