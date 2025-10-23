// lib/data/models/bank_info_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BankInfoModel {
  final String? id;
  final String psychologistId;
  final String accountHolderName;
  final String bankName;
  final String accountType; // 'checking' o 'savings'
  final String accountNumber;
  final String clabe;
  final bool isInternational;
  final String? swiftCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankInfoModel({
    this.id,
    required this.psychologistId,
    required this.accountHolderName,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.clabe,
    this.isInternational = false,
    this.swiftCode,
    this.createdAt,
    this.updatedAt,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      id: json['id'],
      psychologistId: json['psychologistId'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      bankName: json['bankName'] ?? '',
      accountType: json['accountType'] ?? 'checking',
      accountNumber: json['accountNumber'] ?? '',
      clabe: json['clabe'] ?? '',
      isInternational: json['isInternational'] ?? false,
      swiftCode: json['swiftCode'],
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    return null;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'psychologistId': psychologistId,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'clabe': clabe,
      'isInternational': isInternational,
    };

    if (swiftCode != null) {
      json['swiftCode'] = swiftCode;
    }

    if (createdAt != null) {
      json['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    if (updatedAt != null) {
      json['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    return json;
  }

  BankInfoModel copyWith({
    String? id,
    String? psychologistId,
    String? accountHolderName,
    String? bankName,
    String? accountType,
    String? accountNumber,
    String? clabe,
    bool? isInternational,
    String? swiftCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankInfoModel(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      clabe: clabe ?? this.clabe,
      isInternational: isInternational ?? this.isInternational,
      swiftCode: swiftCode ?? this.swiftCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}