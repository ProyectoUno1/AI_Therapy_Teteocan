// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Aurora AI Therapy App';

  // Colores de la paleta
  static const Color primaryColor = Color(0xFF3B716F);
  static const Color accentColor = Color(0xFF5CA0AC);
  static const Color lightAccentColor = Color(0xFF82C4C3);
  static const Color warningColor = Color(0xFFFFF9C4);
  static const Color errorColor = Color(0xFFE57373);

  static const Color secondaryColor = Color(0xFF00A389);
  static const Color lightSecondaryColor = Color(0xFF66D9EF);
  static const Color lightGreyBackground = Color(0xFFF5F5F5);
  static const Color lightGrayColor = Color(0xFFF0F0F0);

  // Rutas de imágenes
  static const String logoAuroraPath = 'assets/images/LogoAurora.png';

  // Duraciones de animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);

  // URLs del backend - ACTUALIZADO PARA RENDER
  static const String baseUrl = kDebugMode
      ? 'http://10.0.2.2:3000/api'  // Desarrollo local
      : 'https://ai-therapy-teteocan.onrender.com/api'; // Producción en Render
}