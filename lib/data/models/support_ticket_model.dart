// lib/data/models/support_ticket_model.dart

class SupportTicket {
  final String? id;
  final String userId;
  final String userEmail;
  final String userName;
  final String userType; // 'patient' o 'psychologist'
  final String subject;
  final String category;
  final String message;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? response;
  final DateTime? responseAt;

  SupportTicket({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userType,
    required this.subject,
    required this.category,
    required this.message,
    this.status = 'open',
    this.priority = 'medium',
    required this.createdAt,
    this.updatedAt,
    this.response,
    this.responseAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userType': userType,
      'subject': subject,
      'category': category,
      'message': message,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'response': response,
      'responseAt': responseAt?.toIso8601String(),
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'],
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      userType: map['userType'] ?? 'patient',
      subject: map['subject'] ?? '',
      category: map['category'] ?? 'general',
      message: map['message'] ?? '',
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      response: map['response'],
      responseAt: map['responseAt'] != null
          ? DateTime.parse(map['responseAt'])
          : null,
    );
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? userType,
    String? subject,
    String? category,
    String? message,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? response,
    DateTime? responseAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      message: message ?? this.message,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      response: response ?? this.response,
      responseAt: responseAt ?? this.responseAt,
    );
  }
}

class FAQ {
  final String question;
  final String answer;
  final String category;
  final List<String> tags;

  FAQ({
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
  });
}