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

  static const String _baseUrl = '${ApiConstants.baseUrl}/stripe';

  PaymentHistoryRepositoryImpl({http.Client? client}) 
      : _client = client ?? http.Client();

  /// Obtiene el token de autenticación de Firebase
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

@override
Future<List<PaymentRecord>> getPaymentHistory() async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    List<PaymentRecord> payments = [];
    Set<String> processedIds = {}; 
    final appointmentsQuery = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .where('isPaid', isEqualTo: true)
        .orderBy('paidAt', descending: true)
        .get();

    for (var doc in appointmentsQuery.docs) {
      final data = doc.data();
      if (!processedIds.contains(doc.id)) {
        payments.add(PaymentRecord(
          id: doc.id,
          type: PaymentType.psychologySession,
          amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0, 
          currency: data['currency'] ?? 'mxn',
          status: _parsePaymentStatus(data['status'] ?? 'completed'),
          date: data['paidAt']?.toDate() ?? data['createdAt']?.toDate() ?? DateTime.now(),
          description: 'Sesión individual con ${data['psychologistName'] ?? 'Psicólogo'}',
          psychologistName: data['psychologistName'],
          sessionDate: data['scheduledDateTime']?.toDate().toString().split(' ')[0],
          sessionTime: data['scheduledDateTime']?.toDate().toString().split(' ')[1].substring(0, 5),
          paymentMethod: _getPaymentMethodText(data['paymentMethod']), 
        ));
        processedIds.add(doc.id);
      }
    }

    final subscriptionPaymentsQuery = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: user.uid)
        .orderBy('paymentDate', descending: true)
        .get();

    for (var doc in subscriptionPaymentsQuery.docs) {
      final data = doc.data();
      
      if (!processedIds.contains(doc.id)) {
        if (data['status'] == 'succeeded') {
          payments.add(PaymentRecord(
            id: doc.id,
            type: PaymentType.subscription,
            amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0,
            currency: data['currency'] ?? 'mxn',
            status: PaymentStatus.completed,
            date: data['paymentDate']?.toDate() ?? DateTime.now(),
            description: 'Pago de Suscripción ${data['planName'] ?? 'Premium'}',
            paymentMethod: _getPaymentMethodText(data['paymentMethod'] ?? 'card'), 
          ));
          processedIds.add(doc.id);
        } else if (data['status'] == 'failed') {
          payments.add(PaymentRecord(
            id: doc.id,
            type: PaymentType.subscription,
            amount: (data['amountDue'] is num) ? (data['amountDue'] as num) / 100 : 0.0,
            currency: data['currency'] ?? 'mxn',
            status: PaymentStatus.failed,
            date: data['attemptedAt']?.toDate() ?? DateTime.now(),
            description: 'Intento de Pago de Suscripción (Fallido)',
            paymentMethod: _getPaymentMethodText(data['paymentMethod'] ?? 'card'), 
          ));
          processedIds.add(doc.id);
        }
      }
    }

    try {
      // Obtener token de autenticación
      final token = await _getAuthToken();
      
      if (token == null) {
        print('No se pudo obtener token de autenticación');
      } else {
        
        final response = await _client.get(
            Uri.parse('$_baseUrl/subscription-status/${user.uid}'),
            headers: {
              'Content-Type': 'application/json', 
              'Accept': 'application/json',
              'Authorization': 'Bearer $token', 
            },
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            if (data['hasSubscription'] == true && data['subscription'] != null) {
                final sub = data['subscription'] as Map<String, dynamic>;
                final subscriptionDate = _parseDateFromDynamic(sub['createdAt']) ?? DateTime.now();
                final amountTotal = (sub['amountTotal'] as num?)?.toDouble() ?? 0.0;
                final subscriptionId = sub['id']?.toString() ?? 'subscription_${user.uid}';

                if (amountTotal > 0 && !processedIds.contains(subscriptionId)) {
                  final initialPaymentRecord = PaymentRecord(
                    id: subscriptionId, 
                    type: PaymentType.subscription,
                    amount: amountTotal / 100, 
                    currency: sub['currency']?.toString() ?? 'mxn',
                    status: _parsePaymentStatus(sub['status']?.toString() ?? 'active'), 
                    date: subscriptionDate, 
                    description: 'Activación de Suscripción ${sub['planName'] ?? 'Premium'}', 
                    paymentMethod: 'Tarjeta de Crédito/Débito',
                  );
                  
                  payments.add(initialPaymentRecord);
                  processedIds.add(subscriptionId);
                } else {
                  print('Pago inicial ya existe o monto es 0');
                }
            } else {
              print('ℹNo hay suscripción activa');
            }
        } else {
          print('Error en la respuesta: ${response.statusCode}');
          print('Body: ${response.body}');
        }
      }
    } catch (e) {
      print('Error al obtener suscripción activa (no crítico): $e');
    }
    payments.sort((a, b) => b.date.compareTo(a.date));
    
    return payments;
  } catch (e) {
    print('Error en getPaymentHistory: $e');
    throw Exception('Error al obtener historial de pagos: ${e.toString()}');
  }
}

@override
Future<List<SubscriptionRecord>> getSubscriptionHistory() async {
  return []; 
}

String _getPaymentMethodText(String? method) {
  if (method == null) {
    return 'Tarjeta de Crédito/Débito';
  }
  switch (method.toLowerCase()) {
    case 'card':
    case 'one_time':
    case 'visa':
    case 'mastercard':
      return 'Tarjeta de Crédito/Débito';
    case 'paypal':
      return 'PayPal';
    case 'bank_transfer':
      return 'Transferencia Bancaria';
    default:
      return 'Tarjeta de Crédito/Débito'; 
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
    print('Error parseando fecha: $e');
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

    print('🔍 Buscando detalles del pago: $paymentId');

    // 1. Buscar en appointments (sesiones individuales)
    var doc = await _firestore.collection('appointments').doc(paymentId).get();
    if (doc.exists && doc.data()?['isPaid'] == true) { 
      print('✅ Encontrado en appointments');
      final data = doc.data()!;
      return PaymentDetails(
        id: doc.id,
        type: PaymentType.psychologySession,
        amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 0.0,
        currency: data['currency'] ?? 'mxn',
        status: _parsePaymentStatus(data['status']),
        date: data['paidAt']?.toDate() ?? data['createdAt']?.toDate() ?? DateTime.now(),
        description: 'Sesión individual con ${data['psychologistName'] ?? 'Psicólogo'}',
        psychologistName: data['psychologistName'],
        sessionDate: data['scheduledDateTime']?.toDate().toString().split(' ')[0],
        sessionTime: data['scheduledDateTime']?.toDate().toString().split(' ')[1].substring(0, 5),
        paymentMethod: _getPaymentMethodText(data['paymentMethod']),
        customerId: data['patientId'],
        paymentIntentId: data['paymentIntentId'],
      );
    }

    // 2. Buscar en payments (pagos recurrentes de suscripción)
    doc = await _firestore.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      print('✅ Encontrado en payments');
      final data = doc.data()!;
      return PaymentDetails(
        id: doc.id,
        type: PaymentType.subscription,
        amount: (data['amountPaid'] is num) ? (data['amountPaid'] as num) / 100 : 
                (data['amountDue'] is num) ? (data['amountDue'] as num) / 100 : 0.0,
        currency: data['currency'] ?? 'mxn',
        status: _parsePaymentStatus(data['status']),
        date: data['paymentDate']?.toDate() ?? data['attemptedAt']?.toDate() ?? DateTime.now(),
        description: data['status'] == 'succeeded' ? 
                    'Pago de Suscripción ${data['planName'] ?? 'Premium'}' : 
                    'Intento de Pago (Fallido)',
        paymentMethod: _getPaymentMethodText(data['paymentMethod'] ?? 'card'),
        customerId: data['customerId'],
        invoiceId: data['invoiceId'],
        subscriptionId: data['subscriptionId'],
      );
    }

    // 3. Buscar suscripción activa (pago inicial)
    if (paymentId.startsWith('sub_') || paymentId.startsWith('subscription_')) {
        print('🔎 Buscando en suscripción activa...');
        
        final token = await _getAuthToken();
        if (token == null) {
          print('⚠️ No se pudo obtener token');
          return null;
        }
        
        final response = await _client.get(
            Uri.parse('$_baseUrl/subscription-status/${user.uid}'),
            headers: {
              'Content-Type': 'application/json', 
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
        );
        
        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['hasSubscription'] == true && data['subscription'] != null) {
                final sub = data['subscription'] as Map<String, dynamic>;
                if (sub['id']?.toString() == paymentId || 'subscription_${user.uid}' == paymentId) {
                     print('✅ Encontrado en suscripción activa');
                     final subscriptionDate = _parseDateFromDynamic(sub['createdAt']) ?? DateTime.now();
                     final amountTotal = (sub['amountTotal'] as num?)?.toDouble() ?? 0.0;

                     return PaymentDetails(
                        id: sub['id']?.toString() ?? 'subscription_${user.uid}',
                        type: PaymentType.subscription,
                        amount: amountTotal / 100,
                        currency: sub['currency']?.toString() ?? 'mxn',
                        status: _parsePaymentStatus(sub['status']?.toString() ?? 'active'), 
                        date: subscriptionDate,
                        description: 'Activación de Suscripción ${sub['planName'] ?? 'Premium'}',
                        paymentMethod: 'Tarjeta de Crédito/Débito',
                        subscriptionId: sub['id']?.toString(),
                        customerId: user.uid,
                      );
                }
            }
        }
    }

    print('❌ Pago no encontrado');
    return null;
  } catch (e) {
    print('❌ Error en getPaymentDetails: $e');
    throw Exception('Error al obtener detalles del pago: ${e.toString()}');
  }
}
}