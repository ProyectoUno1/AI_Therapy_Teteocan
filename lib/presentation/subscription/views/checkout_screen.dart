// lib/presentation/subscription/views/checkout_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';

class CheckoutScreen extends StatefulWidget {
  final String planName;
  final String price;
  final String period;
  final bool isAnnual;
  final String planId;
  final SubscriptionBloc subscriptionBloc;

  const CheckoutScreen({
    super.key,
    required this.planName,
    required this.price,
    required this.period,
    required this.planId,
    required this.subscriptionBloc,
    this.isAnnual = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<SubscriptionState>? _subscriptionBlocStream;
  late AppLinks _appLinks;
  bool _isProcessingPayment = false;
  String? _paymentResult;
  String? _paymentMessage;

  @override
  void initState() {
    super.initState();

    // Escuchar estados del bloc
    _subscriptionBlocStream = widget.subscriptionBloc.stream.listen((state) {
      _handleBlocState(state);
    });

    _initAppLinks();
  }

  void _handleBlocState(SubscriptionState state) {
    if (state is PaymentVerificationSuccess) {
      _setPaymentResult(
        'success',
        '¡Perfecto! Tu suscripción a ${widget.planName} ha sido activada.',
      );

      // Navegar de vuelta después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else if (state is SubscriptionError) {
      _setPaymentResult('error', state.message);
    } else if (state is CheckoutInProgress) {
      _setProcessingState(true);
    } else if (state is CheckoutSuccess) {
      _setProcessingState(false);
    } else if (state is PaymentVerificationInProgress) {
      _setProcessingState(true);
    }
  }

  void _initAppLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) {
        _setPaymentResult('error', 'Error procesando el resultado del pago');
      },
    );

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialLink);
        });
      }
    } catch (e) {
      print('Error al obtener el link inicial: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'auroraapp' && uri.host == 'success') {
      final sessionId = uri.queryParameters['session_id'];
      if (sessionId != null) {
        widget.subscriptionBloc.add(VerifyPaymentSession(sessionId: sessionId));
      }
    }
  }

  void _setProcessingState(bool isProcessing) {
    if (mounted) {
      setState(() {
        _isProcessingPayment = isProcessing;
      });
    }
  }

  void _setPaymentResult(String result, String message) {
    if (mounted) {
      setState(() {
        _paymentResult = result;
        _paymentMessage = message;
        _isProcessingPayment = false;
      });
    }
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(userId)
          .get();
      return patientDoc.data()?['username'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'Usuario';
    } catch (e) {
      return FirebaseAuth.instance.currentUser?.displayName ?? 'Usuario';
    }
  }

  Future<void> _processStripePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setPaymentResult(
        'error',
        'Usuario no autenticado. Por favor, inicia sesión.',
      );
      return;
    }
    final userName = await _getUserName(user.uid);

    widget.subscriptionBloc.add(
      StartCheckoutSession(
        planId: widget.planId,
        planName: widget.planName,
        price: widget.price,
        period: widget.period,
        isAnnual: widget.isAnnual,
        userName: userName,
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _subscriptionBlocStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirmar suscripción',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_paymentResult != null) _buildResultWidget(),
            if (_paymentResult == null) ...[
              _buildSubscriptionSummary(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
              const SizedBox(height: 32),
              _buildCompleteButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSummary() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de tu pedido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu compra será procesada por Stripe.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              'Facturado a: ${user!.email}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.color,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${widget.price}${widget.period}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La suscripción se renovará automáticamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.planName,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${widget.price}${widget.period}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${widget.price}${widget.period}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : _processStripePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessingPayment
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Pagar con Tarjeta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }

  Widget _buildResultWidget() {
    final isSuccess = _paymentResult == 'success';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 100,
        ),
        const SizedBox(height: 20),
        Text(
          isSuccess ? '¡Pago exitoso!' : 'Error en el pago',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            _paymentMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (isSuccess) {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Continuar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
