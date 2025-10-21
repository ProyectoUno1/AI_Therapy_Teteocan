// lib/data/models/payment_model.dart

class PaymentModel {
  final String id;
  final String psychologistId;
  final String patientName;
  final double amount;
  final int sessions;
  final DateTime date;
  final String status; // 'completed', 'pending'
  final String? paymentMethod;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.psychologistId,
    required this.patientName,
    required this.amount,
    required this.sessions,
    required this.date,
    required this.status,
    this.paymentMethod,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String? ?? '',
      psychologistId: json['psychologistId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Sin nombre',
      amount: _parseDouble(json['amount']),
      sessions: json['sessions'] as int? ?? 1,
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
    );
  }

  // Función auxiliar para parsear doubles
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Función auxiliar para parsear fechas de Firebase
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      // Si es un String ISO
      if (value is String) {
        return DateTime.parse(value);
      }
      
      // Si es un Map (Timestamp de Firebase)
      if (value is Map<String, dynamic>) {
        // Firebase Timestamp tiene _seconds y _nanoseconds
        if (value.containsKey('_seconds')) {
          final seconds = value['_seconds'] as int;
          final nanoseconds = value['_nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000)
          );
        }
        // O puede tener seconds y nanoseconds sin guión bajo
        if (value.containsKey('seconds')) {
          final seconds = value['seconds'] as int;
          final nanoseconds = value['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000)
          );
        }
      }
      
      // Si es un int (timestamp en milisegundos)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      
      return null;
    } catch (e) {
      print('Error parseando fecha: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'psychologistId': psychologistId,
      'patientName': patientName,
      'amount': amount,
      'sessions': sessions,
      'date': date.toIso8601String(),
      'status': status,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? psychologistId,
    String? patientName,
    double? amount,
    int? sessions,
    DateTime? date,
    String? status,
    String? paymentMethod,
    String? notes,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      patientName: patientName ?? this.patientName,
      amount: amount ?? this.amount,
      sessions: sessions ?? this.sessions,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}