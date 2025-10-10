

enum PaymentType {
  psychologySession,
  subscription,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum SubscriptionStatus {
  active,
  inactive,
  canceled,
  pastDue,
  trialing,
  incomplete,
}

class PaymentRecord {
  final String id;
  final PaymentType type;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime date;
  final String description;
  final String? psychologistName;
  final String? sessionDate;
  final String? sessionTime;
  final String paymentMethod;

  PaymentRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.description,
    this.psychologistName,
    this.sessionDate,
    this.sessionTime,
    required this.paymentMethod,
  });

  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }
}

class SubscriptionRecord {
  final String id;
  final String planName;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double amount;
  final String currency;
  final bool cancelAtPeriodEnd;
  final String? cancelReason;

  SubscriptionRecord({
    required this.id,
    required this.planName,
    required this.status,
    this.startDate,
    this.endDate,
    required this.amount,
    required this.currency,
    required this.cancelAtPeriodEnd,
    this.cancelReason,
  });

  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';
  }

  String get statusText {
    switch (status) {
      case SubscriptionStatus.active:
        return cancelAtPeriodEnd ? 'Cancelando al final del período' : 'Activa';
      case SubscriptionStatus.inactive:
        return 'Inactiva';
      case SubscriptionStatus.canceled:
        return 'Cancelada';
      case SubscriptionStatus.pastDue:
        return 'Pago vencido';
      case SubscriptionStatus.trialing:
        return 'Período de prueba';
      case SubscriptionStatus.incomplete:
        return 'Incompleta';
    }
  }
}

class PaymentDetails extends PaymentRecord {
  final String? customerId;
  final String? paymentIntentId;
  final String? invoiceId;
  final String? subscriptionId;

  PaymentDetails({
    required super.id,
    required super.type,
    required super.amount,
    required super.currency,
    required super.status,
    required super.date,
    required super.description,
    super.psychologistName,
    super.sessionDate,
    super.sessionTime,
    required super.paymentMethod,
    this.customerId,
    this.paymentIntentId,
    this.invoiceId,
    this.subscriptionId,
  });
}