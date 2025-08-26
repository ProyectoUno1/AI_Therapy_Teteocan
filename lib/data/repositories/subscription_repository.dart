// lib/data/repositories/subscription_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../presentation/subscription/bloc/subscription_state.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionData?> getUserSubscriptionStatus();
  Future<bool> hasActiveSubscription();
  Future<String?> createCheckoutSession({
    required String planId,
    required String planName,
    String? userName,
  });
  Future<bool> verifyPaymentSession(String sessionId);
  Future<String> cancelSubscription({bool immediate = false});
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  static const String baseUrl = 'http://10.0.2.2:3000/api/stripe';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<SubscriptionData?> getUserSubscriptionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Buscar en la colección 'subscriptions' en Firebase
      final subscriptionDocs = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'trialing'])
          .limit(1)
          .get();

      if (subscriptionDocs.docs.isNotEmpty) {
        final doc = subscriptionDocs.docs.first;
        return SubscriptionData.fromFirestore(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener el estado de la suscripción: $e');
    }
  }

  @override
  Future<bool> hasActiveSubscription() async {
    try {
      final subscriptionData = await getUserSubscriptionStatus();
      return subscriptionData?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> createCheckoutSession({
    required String planId,
    required String planName,
    String? userName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener nombre del usuario si no se proporciona
      if (userName == null) {
        try {
          final userDoc = await _firestore
              .collection('patients')
              .doc(user.uid)
              .get();
          userName = userDoc.data()?['username'] ?? user.displayName ?? 'Usuario';
        } catch (e) {
          userName = user.displayName ?? 'Usuario';
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planId': planId,
          'userEmail': user.email!,
          'userId': user.uid,
          'userName': userName,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        if (errorData['error']?.contains('ya tiene una suscripción') == true) {
          throw Exception('Ya tienes una suscripción activa');
        }
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final sessionData = jsonDecode(response.body);
      final String? checkoutUrl = sessionData['checkoutUrl'];

      if (checkoutUrl == null) {
        throw Exception('URL de Checkout no encontrada en la respuesta del servidor');
      }

      return checkoutUrl;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> verifyPaymentSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['paymentStatus'] == 'paid';
      } else {
        throw Exception('Error al verificar el pago con el servidor');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> cancelSubscription({bool immediate = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Buscar la suscripción activa del usuario
      final subscriptionDocs = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'trialing'])
          .limit(1)
          .get();

      if (subscriptionDocs.docs.isEmpty) {
        throw Exception('No se encontró una suscripción activa');
      }

      final subscriptionId = subscriptionDocs.docs.first.id;

      final response = await http.post(
        Uri.parse('$baseUrl/cancel-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'immediate': immediate,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? 'Suscripción cancelada exitosamente';
      } else {
        throw Exception(data['error'] ?? 'Error desconocido al cancelar suscripción');
      }
    } catch (e) {
      rethrow;
    }
  }
}