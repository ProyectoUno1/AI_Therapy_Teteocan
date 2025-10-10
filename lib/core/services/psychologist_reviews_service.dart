// lib/core/services/psychologist_reviews_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PsychologistReview {
  final String id;
  final String patientName;
  final String? profile_picture_url;
  final int rating;
  final String? comment;
  final DateTime ratedAt;
  final String appointmentId;

  PsychologistReview({
    required this.id,
    required this.patientName,
    this.profile_picture_url,
    required this.rating,
    this.comment,
    required this.ratedAt,
    required this.appointmentId,
  });

  factory PsychologistReview.fromJson(Map<String, dynamic> json) {
    return PsychologistReview(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? 'Usuario',
      profile_picture_url: json['profile_picture_url'],
      rating: json['rating'] ?? 0,
      comment: json['ratingComment'],
      ratedAt: DateTime.parse(json['ratedAt']),
      appointmentId: json['id'] ?? '',
    );
  }
}

class PsychologistReviewsService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener todas las reseñas de un psicólogo
  static Future<List<PsychologistReview>> getPsychologistReviews(
    String psychologistId,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
        '$baseUrl/appointments/psychologist-reviews/$psychologistId',
      );

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reviewsList = data['reviews'] as List;

        return reviewsList
            .map((json) => PsychologistReview.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Obtener estadísticas de reseñas de un psicólogo
  static Future<Map<String, dynamic>> getPsychologistRatingStats(
    String psychologistId,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
        '$baseUrl/appointments/psychologist-rating/$psychologistId',
      );

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }
    } catch (e) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }
}