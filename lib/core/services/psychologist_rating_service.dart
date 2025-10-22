// lib/core/services/psychologist_rating_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PsychologistRatingModel {
  final String psychologistId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int>? ratingDistribution;
  final String? error;

  PsychologistRatingModel({
    required this.psychologistId,
    required this.averageRating,
    required this.totalRatings,
    this.ratingDistribution,
    this.error,
  });

  factory PsychologistRatingModel.fromJson(Map<String, dynamic> json) {
    return PsychologistRatingModel(
      psychologistId: json['psychologistId'] ?? '',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      ratingDistribution: json['ratingDistribution'] != null
          ? Map<int, int>.from(json['ratingDistribution'])
          : null,
      error: json['error'],
    );
  }
}

class PsychologistRatingService {
  static const String _baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';
  
  
  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        print(' Token obtenido para usuario: ${user.uid}');
        return token;
      } else {
        print(' No hay usuario autenticado');
        return null;
      }
    } catch (e) {
      print('Error al obtener token: $e');
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  // Obtener rating de un psicólogo específico
  static Future<PsychologistRatingModel?> getPsychologistRating(
    String psychologistId,
  ) async {
    try {
      
      final headers = await _getHeaders();
      final url = '$_baseUrl/appointments/psychologist-rating/$psychologistId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener rating');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final rating = PsychologistRatingModel.fromJson(data);
        return rating;
      } else {
        return PsychologistRatingModel(
          psychologistId: psychologistId,
          averageRating: 0.0,
          totalRatings: 0,
          error: 'Error ${response.statusCode}',
        );
      }
    } catch (e) {
      return PsychologistRatingModel(
        psychologistId: psychologistId,
        averageRating: 0.0,
        totalRatings: 0,
        error: e.toString(),
      );
    }
  }

  // Obtener ratings de múltiples psicólogos
  static Future<Map<String, PsychologistRatingModel>> getPsychologistsRatings(
    List<String> psychologistIds,
  ) async {
    try {

      if (psychologistIds.isEmpty) {
        return {};
      }

      final headers = await _getHeaders();
      final url = '$_baseUrl/appointments/psychologists-ratings';
      final body = json.encode({
        'psychologistIds': psychologistIds,
      });
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout al obtener ratings');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> ratings = data['ratings'] ?? [];
        final Map<String, PsychologistRatingModel> ratingsMap = {};
    
        for (final ratingData in ratings) {
          try {
            final rating = PsychologistRatingModel.fromJson(ratingData);
            ratingsMap[rating.psychologistId] = rating;
          
          } catch (e) {
            print('Error procesando rating: $e');
           
          }
        }
        
        return ratingsMap;
        
      } else {
        // Crear ratings vacíos para cada psicólogo
        final Map<String, PsychologistRatingModel> emptyRatings = {};
        for (final id in psychologistIds) {
          emptyRatings[id] = PsychologistRatingModel(
            psychologistId: id,
            averageRating: 0.0,
            totalRatings: 0,
            error: 'Error ${response.statusCode}',
          );
        }
        return emptyRatings;
      }
    } catch (e) {
      
      // Crear ratings vacíos para cada psicólogo en caso de error
      final Map<String, PsychologistRatingModel> emptyRatings = {};
      for (final id in psychologistIds) {
        emptyRatings[id] = PsychologistRatingModel(
          psychologistId: id,
          averageRating: 0.0,
          totalRatings: 0,
          error: e.toString(),
        );
      }
      return emptyRatings;
    }
  }

  // Método para probar la conectividad
  static Future<bool> testConnection() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/appointments'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}