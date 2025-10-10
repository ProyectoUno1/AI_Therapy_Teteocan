// lib/data/repositories/payment_history_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart'; 
import 'package:ai_therapy_teteocan/data/models/payment_history_model.dart';

abstract class PaymentHistoryRepository {
  Future<List<PaymentRecord>> getPaymentHistory();
  Future<List<SubscriptionRecord>> getSubscriptionHistory(); 
  Future<PaymentDetails?> getPaymentDetails(String paymentId);
}

class PaymentHistoryRepositoryImpl implements PaymentHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final http.Client _client;

  static const String _baseUrl = '${ApiConstants.baseUrl}/api/stripe';

  PaymentHistoryRepositoryImpl({http.Client? client}) 
      : _client = client ?? http.Client();

@override
Future<List<PaymentRecord>> getPaymentHistory() async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    List<PaymentRecord> payments = [];
    final appointmentsQuery = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .where('isPaid', isEqualTo: true) 
        .where('paymentType', isEqualTo: 'one_time') 
        .orderBy('createdAt', descending: true)
        .get();

    for (var doc in appointmentsQuery.docs) {
      final data = doc.data();
      if (data['isPaid'] == true) {
          payments.add(PaymentRecord(
            id: doc.id,
            type: PaymentType.psychologySession,
            amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0, 
            currency: data['currency'] ?? 'usd',
            status: _parsePaymentStatus(data['status'] ?? 'completed'),
            date: data['paidAt']?.toDate() ?? data['createdAt']?.toDate() ?? DateTime.now(),
            description: 'Sesión individual con ${data['psychologistName'] ?? 'Psicólogo'}',
            psychologistName: data['psychologistName'],
            sessionDate: data['scheduledDateTime']?.toDate().toString().split(' ')[0],
            sessionTime: data['scheduledDateTime']?.toDate().toString().split(' ')[1].substring(0, 5),
            paymentMethod: _getPaymentMethodText(data['paymentType']), 
          ));
      }
    }

    final subscriptionPaymentsQuery = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: user.uid)
        .orderBy('paymentDate', descending: true)
        .get();

    for (var doc in subscriptionPaymentsQuery.docs) {
      final data = doc.data();
      payments.add(PaymentRecord(
        id: doc.id,
        type: PaymentType.subscription,
        amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0,
        currency: data['currency'] ?? 'usd',
        status: _parsePaymentStatus(data['status']),
        date: data['paymentDate']?.toDate() ?? DateTime.now(),
        description: 'Pago de Suscripción Premium (Factura)',
        paymentMethod: _getPaymentMethodText(data['paymentMethod']), 
      ));
    }

    final response = await _client.get(
        Uri.parse('$_baseUrl/subscription-status/${user.uid}'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasSubscription'] == true && data['subscription'] != null) {
            final sub = data['subscription'] as Map<String, dynamic>;
            final subscriptionDate = _parseDateFromDynamic(sub['createdAt']) ?? DateTime.now();
            final amountTotal = (sub['amountTotal'] as num?)?.toDouble() ?? 0;
            final paymentMethodKey = sub['paymentMethod']?.toString() ?? 'card'; 
     
            payments.add(PaymentRecord(
              id: sub['id']?.toString() ?? 'subscription_${user.uid}', 
              type: PaymentType.subscription,
              amount: amountTotal / 100, 
              currency: sub['currency']?.toString() ?? 'usd',
              status: _parsePaymentStatus(sub['status']?.toString() ?? 'active'), 
              date: subscriptionDate, 
              description: 'Suscripción Premium (ACTIVA)', 
              paymentMethod: _getPaymentMethodText(paymentMethodKey),
            ));
        }
    }

    payments.sort((a, b) => b.date.compareTo(a.date));

    return payments;
  } catch (e) {
    throw Exception('Error al obtener historial de pagos: ${e.toString()}');
  }
}

@override
Future<List<SubscriptionRecord>> getSubscriptionHistory() async {
  return []; 
}

String _getPaymentMethodText(String? method) {
  if (method == null) {
    return 'Desconocido';
  }
  switch (method.toLowerCase()) {
    case 'card':
    case 'one_time':
    case 'visa':
    case 'mastercard':
      return 'Tarjeta de Crédito/Débito';
    default:
      return method; 
  }
}

DateTime? _parseDateFromDynamic(dynamic dateValue) { 
  if (dateValue == null) return null; 

  try {
    if (dateValue is DateTime) return dateValue.toLocal();
    if (dateValue is String) return DateTime.parse(dateValue).toLocal();
    if (dateValue is Timestamp) return dateValue.toDate().toLocal();
    if (dateValue is Map<String, dynamic>) {
      final secondsKey = dateValue.containsKey('_seconds') ? '_seconds' : (dateValue.containsKey('seconds') ? 'seconds' : null);
      if (secondsKey != null && dateValue[secondsKey] is int) {
        return DateTime.fromMillisecondsSinceEpoch((dateValue[secondsKey] as int) * 1000).toLocal();
      }
    }
    if (dateValue is num) {
      final int value = dateValue.toInt();
      return DateTime.fromMillisecondsSinceEpoch(value.toString().length > 10 ? value : value * 1000).toLocal();
    }
  } catch (e) {
    return null;
  }
  return null;
}

PaymentStatus _parsePaymentStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'succeeded':
    case 'paid':
    case 'completed':
    case 'active':     
    case 'trialing':   
      return PaymentStatus.completed;
    case 'pending':
    case 'processing': 
      return PaymentStatus.pending;
    case 'failed':
    case 'canceled': 
    case 'incomplete': 
      return PaymentStatus.failed;
    case 'refunded':
      return PaymentStatus.refunded;
    default:
      return PaymentStatus.pending;
  }
}

SubscriptionStatus _parseSubscriptionStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'active':
      return SubscriptionStatus.active;
    case 'canceled':
    case 'cancelled':
      return SubscriptionStatus.canceled;
    case 'past_due':
      return SubscriptionStatus.pastDue;
    case 'incomplete':
      return SubscriptionStatus.incomplete;
    case 'trialing':
      return SubscriptionStatus.trialing;
    case 'inactive':
    case 'unpaid': 
      return SubscriptionStatus.inactive;
    default:
      return SubscriptionStatus.inactive;
  }
}


@override
Future<PaymentDetails?> getPaymentDetails(String paymentId) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return null;

    var doc = await _firestore.collection('appointments').doc(paymentId).get();
    if (doc.exists && doc.data()?['paymentType'] == 'one_time') { 
      final data = doc.data()!;
      return PaymentDetails(
        id: doc.id,
        type: PaymentType.psychologySession,
        amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0,
        currency: data['currency'] ?? 'usd',
        status: _parsePaymentStatus(data['status']),
        date: data['paidAt']?.toDate() ?? data['createdAt']?.toDate() ?? DateTime.now(),
        description: 'Sesión individual con ${data['psychologistName'] ?? 'Psicólogo'}',
        psychologistName: data['psychologistName'],
        sessionDate: data['scheduledDateTime']?.toDate().toString().split(' ')[0],
        sessionTime: data['scheduledDateTime']?.toDate().toString().split(' ')[1].substring(0, 5),
        paymentMethod: _getPaymentMethodText(data['paymentType']),
        customerId: data['patientId'],
        paymentIntentId: data['paymentIntentId'],
      );
    }

    doc = await _firestore.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return PaymentDetails(
        id: doc.id,
        type: PaymentType.subscription,
        amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0,
        currency: data['currency'] ?? 'usd',
        status: _parsePaymentStatus(data['status']),
        date: data['paymentDate']?.toDate() ?? DateTime.now(),
        description: 'Pago de Suscripción Premium (Factura)',
        paymentMethod: _getPaymentMethodText(data['paymentMethod']),
        customerId: data['customerId'],
        invoiceId: data['invoiceId'],
        subscriptionId: data['subscriptionId'],
      );
    }

    if (paymentId.startsWith('sub_') || paymentId.startsWith('subscription_')) {
        final response = await _client.get(
            Uri.parse('$_baseUrl/subscription-status/${user.uid}'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        );
        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['hasSubscription'] == true && data['subscription'] != null) {
                final sub = data['subscription'] as Map<String, dynamic>;
                if (sub['id']?.toString() == paymentId || 'subscription_${user.uid}' == paymentId) {
                     final subscriptionDate = _parseDateFromDynamic(sub['createdAt']) ?? DateTime.now();
                     final amountTotal = (sub['amountTotal'] as num?)?.toDouble() ?? 0;
                     final paymentMethodKey = sub['paymentMethod']?.toString() ?? 'card';

                     return PaymentDetails(
                        id: sub['id']?.toString() ?? 'subscription_${user.uid}',
                        type: PaymentType.subscription,
                        amount: amountTotal / 100,
                        currency: sub['currency']?.toString() ?? 'usd',
                        status: _parsePaymentStatus(sub['status']?.toString() ?? 'active'), 
                        date: subscriptionDate,
                        description: 'Suscripción Premium (ACTIVA)',
                        paymentMethod: _getPaymentMethodText(paymentMethodKey),
                        subscriptionId: sub['id']?.toString(),
                        customerId: user.uid,
                      );
                }
            }
        }
    }

    return null;
  } catch (e) {
    throw Exception('Error al obtener detalles del pago: ${e.toString()}');
  }
}
}
