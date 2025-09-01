// lib/core/services/subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/stripe';

  // OBTENER ESTADO DE SUSCRIPCIÓN DEL USUARIO
static Future<SubscriptionStatus?> getUserSubscriptionStatus() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Buscar SOLO en la colección 'subscriptions'
    final subscriptionDocs = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (subscriptionDocs.docs.isNotEmpty) {
      final subscriptionData = subscriptionDocs.docs.first.data();
      final subscriptionDoc = subscriptionDocs.docs.first;
      
      return SubscriptionStatus(
        hasSubscription: true,
        subscription: SubscriptionData.fromJson({
          'id': subscriptionDoc.id,
          'status': subscriptionData['status'] ?? 'active',
          'currentPeriodEnd': subscriptionData['currentPeriodEnd']?.toDate(),
          'cancelAtPeriodEnd': subscriptionData['cancelAtPeriodEnd'] ?? false,
          'userId': subscriptionData['userId'],
          'userEmail': subscriptionData['userEmail'] ?? user.email,
          'userName': subscriptionData['userName'] ?? user.displayName,
          'planName': subscriptionData['planName'] ?? 'Premium'
        })
      );
    }

    // Si no encuentra suscripción activa, retornar null
    return null;

  } catch (e) {
    print("Error al obtener el estado de la suscripción: $e");
    return null;
  }
}

  // VERIFICAR SI EL USUARIO TIENE SUSCRIPCIÓN ACTIVA
  static Future<bool> hasActiveSubscription() async {
    try {
      final status = await getUserSubscriptionStatus();
      return status?.hasSubscription == true &&
          status?.subscription?.isActive == true;
    } catch (e) {
      print('Error verificando suscripción activa: $e');
      return false;
    }
  }

  // CANCELAR SUSCRIPCIÓN
static Future<CancellationResult> cancelSubscription({
  bool immediate = false,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Primero buscar la suscripción activa del usuario
    final subscriptionDocs = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (subscriptionDocs.docs.isEmpty) {
      return CancellationResult(
        success: false,
        message: 'No se encontró una suscripción activa',
        subscription: null,
      );
    }

    final subscriptionId = subscriptionDocs.docs.first.id;

    final response = await http.post(
      Uri.parse('$baseUrl/cancel-subscription'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subscriptionId': subscriptionId,
        'immediate': immediate
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return CancellationResult(
        success: true,
        message: data['message'],
        subscription: data['subscription'] != null
            ? SubscriptionData.fromJson(data['subscription'])
            : null,
      );
    } else {
      return CancellationResult(
        success: false,
        message: data['error'] ?? 'Error desconocido',
        subscription: null,
      );
    }
  } catch (e) {
    print('Error cancelando suscripción: $e');
    return CancellationResult(
      success: false,
      message: 'Error al cancelar suscripción: $e',
      subscription: null,
    );
  }
}

  // CREAR SESIÓN DE CHECKOUT
  static Future<CheckoutResult> createCheckoutSession({
    required String planId,
    String? userName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener nombre del usuario si no se proporciona
      if (userName == null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          userName = userDoc.data()?['name'] ?? user.displayName ?? 'Usuario';
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return CheckoutResult(
          success: true,
          checkoutUrl: data['checkoutUrl'],
          sessionId: data['sessionId'],
          error: null,
        );
      } else {
        return CheckoutResult(
          success: false,
          checkoutUrl: null,
          sessionId: null,
          error: data['error'] ?? 'Error desconocido',
        );
      }
    } catch (e) {
      print('Error creando sesión de checkout: $e');
      return CheckoutResult(
        success: false,
        checkoutUrl: null,
        sessionId: null,
        error: 'Error al crear sesión de checkout: $e',
      );
    }
  }

  // VERIFICAR ESTADO DE SESIÓN
  static Future<SessionVerificationResult> verifySession(
    String sessionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SessionVerificationResult(
          success: true,
          paymentStatus: data['paymentStatus'],
          sessionStatus: data['sessionStatus'],
          subscriptionId: data['subscriptionId'],
          subscriptionStatus: data['subscriptionStatus'],
          customerId: data['customerId'],
          customerEmail: data['customerEmail'],
          amountTotal: data['amountTotal'],
          currency: data['currency'],
          error: null,
        );
      } else {
        return SessionVerificationResult(
          success: false,
          error: data['error'] ?? 'Error desconocido',
        );
      }
    } catch (e) {
      print('Error verificando sesión: $e');
      return SessionVerificationResult(
        success: false,
        error: 'Error al verificar sesión: $e',
      );
    }
  }

  static Future<void> updateLocalSubscriptionStatus({
  required bool hasSubscription,
  String? subscriptionId,
  String? customerId,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, Object?> updateData = {
      'hasSubscription': hasSubscription,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (subscriptionId != null) {
      updateData['subscriptionId'] = subscriptionId;
    }

    if (customerId != null) {
      updateData['stripeCustomerId'] = customerId;
    }

    if (additionalData != null) {
      updateData.addAll(additionalData);
    }
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));

  } catch (e) {
    print('Error actualizando estado local: $e');
  }
}
}

// MODELOS DE DATOS

class SubscriptionStatus {
  final bool hasSubscription;
  final SubscriptionData? subscription;

  SubscriptionStatus({required this.hasSubscription, this.subscription});

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      hasSubscription: json['hasSubscription'] ?? false,
      subscription: json['subscription'] != null
          ? SubscriptionData.fromJson(json['subscription'])
          : null,
    );
  }
}

class SubscriptionData {
  final String id;
  final String status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? planName;

  SubscriptionData({
    required this.id,
    required this.status,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.userId,
    this.userEmail,
    this.userName,
    this.planName,
  });

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled';
  bool get isPastDue => status == 'past_due';

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'])
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
      userId: json['userId'],
      userEmail: json['userEmail'],
      userName: json['userName'],
      planName: json['planName'],
    );
  }
}

class CancellationResult {
  final bool success;
  final String message;
  final SubscriptionData? subscription;

  CancellationResult({
    required this.success,
    required this.message,
    this.subscription,
  });
}

class CheckoutResult {
  final bool success;
  final String? checkoutUrl;
  final String? sessionId;
  final String? error;

  CheckoutResult({
    required this.success,
    this.checkoutUrl,
    this.sessionId,
    this.error,
  });
}

class SessionVerificationResult {
  final bool success;
  final String? paymentStatus;
  final String? sessionStatus;
  final String? subscriptionId;
  final String? subscriptionStatus;
  final String? customerId;
  final String? customerEmail;
  final int? amountTotal;
  final String? currency;
  final String? error;

  SessionVerificationResult({
    required this.success,
    this.paymentStatus,
    this.sessionStatus,
    this.subscriptionId,
    this.subscriptionStatus,
    this.customerId,
    this.customerEmail,
    this.amountTotal,
    this.currency,
    this.error,
  });
}
