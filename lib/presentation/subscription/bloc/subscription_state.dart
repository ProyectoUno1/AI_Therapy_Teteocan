// lib/presentation/subscription/bloc/subscription_state.dart

import 'package:equatable/equatable.dart';

abstract class SubscriptionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final bool hasActiveSubscription;
  final SubscriptionData? subscriptionData;

  SubscriptionLoaded({
    required this.hasActiveSubscription,
    this.subscriptionData,
  });

  @override
  List<Object?> get props => [hasActiveSubscription, subscriptionData];
}

class CheckoutInProgress extends SubscriptionState {}

class CheckoutSuccess extends SubscriptionState {
  final String message;

  CheckoutSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PaymentVerificationInProgress extends SubscriptionState {}

class PaymentVerificationSuccess extends SubscriptionState {
  final String message;

  PaymentVerificationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class SubscriptionCancellationInProgress extends SubscriptionState {}

class SubscriptionCancellationSuccess extends SubscriptionState {
  final String message;

  SubscriptionCancellationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  SubscriptionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Modelo de datos para la suscripción
class SubscriptionData extends Equatable {
  final String id;
  final String status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? planName;
  final double? amount;
  final String? currency;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  const SubscriptionData({
    required this.id,
    required this.status,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.userId,
    this.userEmail,
    this.userName,
    this.planName,
    this.amount,
    this.currency,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
  });

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isCanceled => status == 'canceled';
  bool get isPastDue => status == 'past_due';

  factory SubscriptionData.fromFirestore(Map<String, dynamic> data, String docId) {
    return SubscriptionData(
      id: docId,
      status: data['status'] ?? '',
      currentPeriodEnd: data['currentPeriodEnd']?.toDate(),
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] ?? false,
      userId: data['userId'],
      userEmail: data['userEmail'],
      userName: data['userName'],
      planName: data['planName'],
      amount: data['amount']?.toDouble(),
      currency: data['currency'],
      stripeCustomerId: data['stripeCustomerId'],
      stripeSubscriptionId: data['stripeSubscriptionId'],
    );
  }

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? (json['currentPeriodEnd'] is DateTime
              ? json['currentPeriodEnd']
              : DateTime.parse(json['currentPeriodEnd']))
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
      userId: json['userId'],
      userEmail: json['userEmail'],
      userName: json['userName'],
      planName: json['planName'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      stripeCustomerId: json['stripeCustomerId'],
      stripeSubscriptionId: json['stripeSubscriptionId'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        userId,
        userEmail,
        userName,
        planName,
        amount,
        currency,
        stripeCustomerId,
        stripeSubscriptionId,
      ];
}