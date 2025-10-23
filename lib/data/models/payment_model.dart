// lib/data/models/payment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String psychologistId;
  final String psychologistName;
  final String psychologistEmail;
  final String paidBy;
  final double amount;
  final double calculatedAmount;
  final int appointmentsCount;
  final List<String> appointmentIds;
  final String status; // 'completed' o 'pending'
  final String paymentMethod; // 'bank_transfer'
  final DateTime paidAt;
  final DateTime registeredAt;
  final String reference;
  final String notes;
  final BankInfoData? bankInfo;
  final ReceiptData? receipt;

  PaymentModel({
    required this.id,
    required this.psychologistId,
    required this.psychologistName,
    required this.psychologistEmail,
    required this.paidBy,
    required this.amount,
    required this.calculatedAmount,
    required this.appointmentsCount,
    required this.appointmentIds,
    required this.status,
    required this.paymentMethod,
    required this.paidAt,
    required this.registeredAt,
    required this.reference,
    this.notes = '',
    this.bankInfo,
    this.receipt,
  });

  // Getter para obtener el nombre del paciente (compatible con UI existente)
  String get patientName => 'Paciente'; // Puedes obtenerlo de otra colección si necesitas

  // Getter para sesiones (compatible con UI existente)
  int get sessions => appointmentsCount;

  // Getter para fecha (compatible con UI existente)
  DateTime get date => paidAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      psychologistId: json['psychologistId'] ?? '',
      psychologistName: json['psychologistName'] ?? '',
      psychologistEmail: json['psychologistEmail'] ?? '',
      paidBy: json['paidBy'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      calculatedAmount: (json['calculatedAmount'] ?? 0).toDouble(),
      appointmentsCount: json['appointmentsCount'] ?? 0,
      appointmentIds: List<String>.from(json['appointmentIds'] ?? []),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'bank_transfer',
      paidAt: _parseTimestamp(json['paidAt']),
      registeredAt: _parseTimestamp(json['registeredAt']),
      reference: json['reference'] ?? '',
      notes: json['notes'] ?? '',
      bankInfo: json['bankInfo'] != null 
          ? BankInfoData.fromJson(json['bankInfo']) 
          : null,
      receipt: json['receipt'] != null 
          ? ReceiptData.fromJson(json['receipt']) 
          : null,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'psychologistId': psychologistId,
      'psychologistName': psychologistName,
      'psychologistEmail': psychologistEmail,
      'paidBy': paidBy,
      'amount': amount,
      'calculatedAmount': calculatedAmount,
      'appointmentsCount': appointmentsCount,
      'appointmentIds': appointmentIds,
      'status': status,
      'paymentMethod': paymentMethod,
      'paidAt': Timestamp.fromDate(paidAt),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'reference': reference,
      'notes': notes,
      'bankInfo': bankInfo?.toJson(),
      'receipt': receipt?.toJson(),
    };
  }
}

class BankInfoData {
  final String accountHolder;
  final String bankName;
  final String clabe;

  BankInfoData({
    required this.accountHolder,
    required this.bankName,
    required this.clabe,
  });

  factory BankInfoData.fromJson(Map<String, dynamic> json) {
    return BankInfoData(
      accountHolder: json['accountHolder'] ?? '',
      bankName: json['bankName'] ?? '',
      clabe: json['clabe'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountHolder': accountHolder,
      'bankName': bankName,
      'clabe': clabe,
    };
  }
}

class ReceiptData {
  final String base64;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String uploadedAt;
  final String uploadedBy;

  ReceiptData({
    required this.base64,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      base64: json['base64'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      fileType: json['fileType'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base64': base64,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
    };
  }
}