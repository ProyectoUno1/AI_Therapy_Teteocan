// lib/data/services/plans_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/plan_model.dart';
import '../../core/constants/app_constants.dart';

class PlansService {
  static const String baseUrl = AppConstants.baseUrl;

  Future<List<PlanModel>> getAvailablePlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stripe/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> plansJson = data['plans'];
        
        return plansJson
            .map((planJson) => PlanModel.fromJson(planJson))
            .toList();
      } else {
        throw Exception('Error al obtener planes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}