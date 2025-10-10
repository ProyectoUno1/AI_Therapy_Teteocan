// lib/data/models/plan_model.dart
class PlanModel {
  final String id;
  final String productId;
  final String productName;
  final String planName;
  final int amount;
  final String currency;
  final String? interval;
  final int? intervalCount;
  final String displayPrice;
  final bool isAnnual;

  const PlanModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.planName,
    required this.amount,
    required this.currency,
    this.interval,
    this.intervalCount,
    required this.displayPrice,
    required this.isAnnual,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      planName: json['planName'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      interval: json['interval'] as String?,
      intervalCount: json['intervalCount'] as int?,
      displayPrice: json['displayPrice'] as String,
      isAnnual: json['isAnnual'] as bool,
    );
  }
}