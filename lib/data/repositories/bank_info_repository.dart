import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankInfoRepository {
  static const String _baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BankInfoRepository();

  // Método para obtener headers con token de autenticación
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final user = _auth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken(true);
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      } else {
        throw Exception('No se pudo obtener el token de autenticación.');
      }
    } else {
      throw Exception('Usuario no autenticado.');
    }

    return headers;
  }

  // Obtener información bancaria del psicólogo
  Future<BankInfoModel?> getBankInfo(String psychologistId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bank-info/$psychologistId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['bankInfo'] != null) {
          return BankInfoModel.fromJson(data['bankInfo']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener información bancaria');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Guardar nueva información bancaria
  Future<BankInfoModel> saveBankInfo(BankInfoModel bankInfo) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bank-info'),
        headers: await _getHeaders(),
        body: json.encode(bankInfo.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return BankInfoModel.fromJson(data['bankInfo']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al guardar información bancaria');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar información bancaria
  Future<BankInfoModel> updateBankInfo(BankInfoModel bankInfo) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/bank-info/${bankInfo.psychologistId}'),
        headers: await _getHeaders(),
        body: json.encode(bankInfo.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BankInfoModel.fromJson(data['bankInfo']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar información bancaria');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener historial de pagos
  Future<List<PaymentModel>> getPaymentHistory(
    String psychologistId, {
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/payments/$psychologistId';
      if (status != null && status != 'all') {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> paymentsJson = data['payments'] ?? [];
        return paymentsJson
            .map((json) => PaymentModel.fromJson(json))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener historial de pagos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
