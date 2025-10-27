// lib/core/constants/api_constants.dart

import 'package:flutter/foundation.dart';

class ApiConstants {
  // URL base del backend
  static const String baseUrl =  'https://ai-therapy-teteocan.onrender.com/api'; // Producción en Render
  
  // Endpoints específicos 
  static const String patientsEndpoint = '/patients';
  static const String psychologistsEndpoint = '/psychologists';
  static const String appointmentsEndpoint = '/appointments';
  static const String chatEndpoint = '/chats';
  static const String stripeEndpoint = '/stripe';
  static const String notificationsEndpoint = '/notifications';
  static const String articlesEndpoint = '/articles';
  
  // Helper para construir URLs completas
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}