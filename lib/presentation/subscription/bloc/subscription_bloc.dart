// lib/presentation/subscription/bloc/subscription_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_therapy_teteocan/data/repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

  SubscriptionBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(SubscriptionInitial()) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<StartCheckoutSession>(_onStartCheckoutSession);
    on<VerifyPaymentSession>(_onVerifyPaymentSession);
    on<CancelSubscription>(_onCancelSubscription);
    on<ResetSubscriptionState>(_onResetSubscriptionState);
  }

  Future<void> _onLoadSubscriptionStatus(
    LoadSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());

      final subscriptionData = await _repository.getUserSubscriptionStatus();
      
      emit(SubscriptionLoaded(
        hasActiveSubscription: subscriptionData?.isActive ?? false,
        subscriptionData: subscriptionData,
      ));
    } catch (e) {
      emit(SubscriptionError(message: 'Error al cargar el estado de la suscripción: $e'));
    }
  }

  Future<void> _onStartCheckoutSession(
    StartCheckoutSession event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(CheckoutInProgress());

      // Verificar si ya tiene suscripción activa antes de proceder
      final hasActive = await _repository.hasActiveSubscription();
      if (hasActive) {
        emit(SubscriptionError(message: 'Ya tienes una suscripción activa'));
        return;
      }

      final checkoutUrl = await _repository.createCheckoutSession(
        planId: event.planId,
        planName: event.planName,
        userName: event.userName,
      );

      if (checkoutUrl != null) {
        // Lanzar el checkout de Stripe
        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
          emit(CheckoutSuccess(
            message: 'Iniciando el proceso de pago...',
          ));
        } else {
          throw 'No se pudo abrir la URL: $checkoutUrl';
        }
      } else {
        throw 'No se pudo crear la sesión de checkout';
      }
    } catch (e) {
      emit(SubscriptionError(message: 'Error al procesar el pago: $e'));
    }
  }

  Future<void> _onVerifyPaymentSession(
    VerifyPaymentSession event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(PaymentVerificationInProgress());

      final isPaymentSuccessful = await _repository.verifyPaymentSession(event.sessionId);

      if (isPaymentSuccessful) {
        // Esperar un poco para que el webhook procese
        await Future.delayed(const Duration(seconds: 3));

        emit(PaymentVerificationSuccess(
          message: 'Pago verificado exitosamente. Tu suscripción está activa.',
        ));

        // Recargar el estado de la suscripción
        add(LoadSubscriptionStatus());
      } else {
        emit(SubscriptionError(message: 'El pago no se completó correctamente'));
      }
    } catch (e) {
      emit(SubscriptionError(message: 'Error al verificar el pago: $e'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionCancellationInProgress());

      final message = await _repository.cancelSubscription(immediate: event.immediate);

      emit(SubscriptionCancellationSuccess(message: message));

      // Recargar el estado de la suscripción después de cancelar
      add(LoadSubscriptionStatus());
    } catch (e) {
      emit(SubscriptionError(message: 'Error al cancelar la suscripción: $e'));
    }
  }

  void _onResetSubscriptionState(
    ResetSubscriptionState event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(SubscriptionInitial());
  }
}