// lib/data/models/subscription_model.dart

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // 'month', 'year'
  final List<String> features;
  final bool isPopular;
  final String? stripePriceId;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'MXN',
    this.interval = 'month',
    required this.features,
    this.isPopular = false,
    this.stripePriceId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'] ?? 'MXN',
      interval: json['interval'] ?? 'month',
      features: List<String>.from(json['features']),
      isPopular: json['isPopular'] ?? false,
      stripePriceId: json['stripePriceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'isPopular': isPopular,
      'stripePriceId': stripePriceId,
    };
  }
}

class UserSubscription {
  final String id;
  final String planId;
  final String status; // 'active', 'inactive', 'cancelled', 'expired'
  final DateTime startDate;
  final DateTime? endDate;
  final String? stripeSubscriptionId;
  final bool autoRenew;

  const UserSubscription({
    required this.id,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.stripeSubscriptionId,
    this.autoRenew = true,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      planId: json['planId'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      stripeSubscriptionId: json['stripeSubscriptionId'],
      autoRenew: json['autoRenew'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'stripeSubscriptionId': stripeSubscriptionId,
      'autoRenew': autoRenew,
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired =>
      status == 'expired' || (endDate?.isBefore(DateTime.now()) ?? false);
}
