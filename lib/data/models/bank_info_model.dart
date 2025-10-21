//lib/data/models/bank_info_model.dart

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
  final bool isVerified;

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
    this.isVerified = false,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      id: json['id'] as String?,
      psychologistId: json['psychologistId'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountType: json['accountType'] as String? ?? 'checking',
      accountNumber: json['accountNumber'] as String? ?? '',
      clabe: json['clabe'] as String? ?? '',
      isInternational: json['isInternational'] as bool? ?? false,
      swiftCode: json['swiftCode'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isVerified: json['isVerified'] as bool? ?? false,
    );
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
      if (id != null) 'id': id,
      'psychologistId': psychologistId,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'clabe': clabe,
      'isInternational': isInternational,
      if (swiftCode != null) 'swiftCode': swiftCode,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isVerified': isVerified,
    };
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
    bool? isVerified,
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
      isVerified: isVerified ?? this.isVerified,
    );
  }
}