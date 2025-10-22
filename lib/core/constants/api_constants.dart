// lib/core/constants/api_constants.dart

import 'package:flutter/foundation.dart';

class ApiConstants {
  // Cambia según el ambiente
  static const String baseUrl = kDebugMode 
    ? 'http://10.0.2.2:3000'  // Desarrollo local (emulador Android)
    : 'https://ai-therapy-teteocan.onrender.com/api'; // Producción en Render
}