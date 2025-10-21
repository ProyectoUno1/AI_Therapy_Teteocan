// lib/presentation/subscription/bloc/subscription_event.dart

abstract class SubscriptionEvent {}

class LoadSubscriptionStatus extends SubscriptionEvent {}

class StartCheckoutSession extends SubscriptionEvent {
  final String planId;
  final String planName;
  final String price;
  final String period;
  final bool isAnnual;
  final String? userName;

  StartCheckoutSession({
    required this.planId,
    required this.planName,
    required this.price,
    required this.period,
    this.isAnnual = false,
    this.userName,
  });
}

class VerifyPaymentSession extends SubscriptionEvent {
  final String sessionId;

  VerifyPaymentSession({required this.sessionId});
}

class CancelSubscription extends SubscriptionEvent {
  final bool immediate;

  CancelSubscription({this.immediate = false});
}

class ResetSubscriptionState extends SubscriptionEvent {}

class UpdatePremiumStatus extends SubscriptionEvent {
  final bool isPremium;

  UpdatePremiumStatus({required this.isPremium});
}