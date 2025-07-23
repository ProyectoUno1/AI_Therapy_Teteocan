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
