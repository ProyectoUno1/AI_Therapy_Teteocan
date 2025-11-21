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
    
    widget.subscriptionBloc.add(StartCheckoutSession(
      planId: widget.planId,
      planName: widget.planName,
      price: widget.price,
      period: widget.period,
      isAnnual: widget.isAnnual,
      userName: userName,
    ));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = screenWidth > 600;
          final isDesktop = screenWidth > 1200;
          
          return OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              
              return Column(
                children: [
                  _buildResponsiveAppBar(screenWidth, isTablet),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: _getAdaptivePadding(screenWidth, isLandscape),
                      child: _paymentResult != null
                          ? _buildResultWidget(screenWidth, screenHeight, isTablet)
                          : _buildCheckoutContent(
                              screenWidth,
                              screenHeight,
                              isTablet,
                              isDesktop,
                              isLandscape,
                            ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ✅ APPBAR RESPONSIVO
  Widget _buildResponsiveAppBar(double screenWidth, bool isTablet) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      pinned: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: _getIconSize(screenWidth),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Confirmar suscripción',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: _getTitleSize(screenWidth),
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      centerTitle: !isTablet,
    );
  }

  // ✅ CONTENIDO PRINCIPAL
  Widget _buildCheckoutContent(
    double screenWidth,
    double screenHeight,
    bool isTablet,
    bool isDesktop,
    bool isLandscape,
  ) {
    if (isLandscape && isTablet) {
      // Layout horizontal para tablets y desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 3 : 2,
            child: Column(
              children: [
                _buildSubscriptionSummary(screenWidth, isTablet),
                SizedBox(height: _getSpacing(screenWidth)),
              ],
            ),
          ),
          SizedBox(width: _getSpacing(screenWidth)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildOrderSummary(screenWidth, isTablet),
                SizedBox(height: _getSpacing(screenWidth) * 2),
                _buildCompleteButton(screenWidth, isTablet),
              ],
            ),
          ),
        ],
      );
    }

    // Layout vertical para móviles y tablets en portrait
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubscriptionSummary(screenWidth, isTablet),
        SizedBox(height: _getSpacing(screenWidth)),
        _buildOrderSummary(screenWidth, isTablet),
        SizedBox(height: _getSpacing(screenWidth) * 2),
        _buildCompleteButton(screenWidth, isTablet),
        SizedBox(height: _getSpacing(screenWidth)),
      ],
    );
  }

  // ✅ RESUMEN DE SUSCRIPCIÓN RESPONSIVO
  Widget _buildSubscriptionSummary(double screenWidth, bool isTablet) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Resumen de tu pedido',
            style: TextStyle(
              fontSize: _getTitleSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: _getSpacing(screenWidth) * 0.5),
          Text(
            'Tu compra será procesada por Stripe.',
            style: TextStyle(
              fontSize: _getSmallTextSize(screenWidth),
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          if (user?.email != null) ...[
            SizedBox(height: _getSpacing(screenWidth) * 0.5),
            Text(
              'Facturado a: ${user!.email}',
              style: TextStyle(
                fontSize: _getSmallTextSize(screenWidth),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: _getSpacing(screenWidth) * 1.5),
          Row(
            children: [
              Container(
                width: _getIconContainerSize(screenWidth),
                height: _getIconContainerSize(screenWidth),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth) * 0.7),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppConstants.primaryColor,
                  size: _getIconSize(screenWidth) * 1.2,
                ),
              ),
              SizedBox(width: _getSpacing(screenWidth)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planName,
                      style: TextStyle(
                        fontSize: _getSubtitleSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${widget.price}${widget.period}',
                      style: TextStyle(
                        fontSize: _getSmallTextSize(screenWidth),
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpacing(screenWidth)),
          Container(
            padding: EdgeInsets.all(_getSpacing(screenWidth) * 0.8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth) * 0.7),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: _getIconSize(screenWidth) * 0.9,
                ),
                SizedBox(width: _getSpacing(screenWidth) * 0.6),
                Expanded(
                  child: Text(
                    'La suscripción se renovará automáticamente',
                    style: TextStyle(
                      fontSize: _getSmallTextSize(screenWidth),
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

  // ✅ RESUMEN DE ORDEN RESPONSIVO
  Widget _buildOrderSummary(double screenWidth, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Resumen',
            style: TextStyle(
              fontSize: _getSubtitleSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: _getSpacing(screenWidth)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.planName,
                  style: TextStyle(
                    fontSize: _getSmallTextSize(screenWidth),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: _getSpacing(screenWidth) * 0.5),
              Text(
                '${widget.price}${widget.period}',
                style: TextStyle(
                  fontSize: _getSmallTextSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpacing(screenWidth) * 0.8),
          Divider(color: Colors.grey[300]),
          SizedBox(height: _getSpacing(screenWidth) * 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: _getSubtitleSize(screenWidth),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${widget.price}${widget.period}',
                style: TextStyle(
                  fontSize: _getSubtitleSize(screenWidth),
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

  // ✅ BOTÓN DE PAGO RESPONSIVO
  Widget _buildCompleteButton(double screenWidth, bool isTablet) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      child: SizedBox(
        width: double.infinity,
        height: _getButtonHeight(screenWidth),
        child: ElevatedButton(
          onPressed: _isProcessingPayment ? null : _processStripePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
            ),
            elevation: 0,
          ),
          child: _isProcessingPayment
              ? SizedBox(
                  width: _getIconSize(screenWidth),
                  height: _getIconSize(screenWidth),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Pagar con Tarjeta',
                  style: TextStyle(
                    fontSize: _getSubtitleSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }

  // ✅ WIDGET DE RESULTADO RESPONSIVO
  Widget _buildResultWidget(double screenWidth, double screenHeight, bool isTablet) {
    final isSuccess = _paymentResult == 'success';
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          minHeight: screenHeight * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: _getIconSize(screenWidth) * 4,
            ),
            SizedBox(height: _getSpacing(screenWidth) * 1.5),
            Text(
              isSuccess ? '¡Pago exitoso!' : 'Error en el pago',
              style: TextStyle(
                fontSize: _getTitleSize(screenWidth) * 1.3,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _getSpacing(screenWidth)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _getSpacing(screenWidth) * 2),
              child: Text(
                _paymentMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getSubtitleSize(screenWidth),
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(height: _getSpacing(screenWidth) * 3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _getSpacing(screenWidth) * 2),
              child: SizedBox(
                width: double.infinity,
                height: _getButtonHeight(screenWidth),
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
                      borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getSubtitleSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FUNCIONES DE DIMENSIONES ADAPTATIVAS
  EdgeInsets _getAdaptivePadding(double screenWidth, bool isLandscape) {
    if (screenWidth > 1200) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.15,
        vertical: isLandscape ? 16 : 24,
      );
    } else if (screenWidth > 800) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.1,
        vertical: isLandscape ? 12 : 20,
      );
    } else if (screenWidth > 600) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08,
        vertical: isLandscape ? 8 : 16,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: screenWidth * 0.05,
      vertical: isLandscape ? 8 : 12,
    );
  }

  EdgeInsets _getCardPadding(double screenWidth) {
    if (screenWidth > 1200) return const EdgeInsets.all(28);
    if (screenWidth > 800) return const EdgeInsets.all(24);
    if (screenWidth > 600) return const EdgeInsets.all(20);
    return const EdgeInsets.all(16);
  }

  double _getTitleSize(double screenWidth) {
    if (screenWidth > 1200) return 20;
    if (screenWidth > 800) return 19;
    if (screenWidth > 600) return 18;
    return 17;
  }

  double _getSubtitleSize(double screenWidth) {
    if (screenWidth > 1200) return 17;
    if (screenWidth > 800) return 16;
    if (screenWidth > 600) return 15;
    return 14;
  }

  double _getSmallTextSize(double screenWidth) {
    if (screenWidth > 1200) return 15;
    if (screenWidth > 800) return 14;
    if (screenWidth > 600) return 13;
    return 12;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth > 1200) return 24;
    if (screenWidth > 800) return 22;
    if (screenWidth > 600) return 20;
    return 18;
  }

  double _getIconContainerSize(double screenWidth) {
    if (screenWidth > 1200) return 60;
    if (screenWidth > 800) return 55;
    if (screenWidth > 600) return 50;
    return 45;
  }

  double _getBorderRadius(double screenWidth) {
    if (screenWidth > 1200) return 16;
    if (screenWidth > 800) return 14;
    if (screenWidth > 600) return 12;
    return 10;
  }

  double _getSpacing(double screenWidth) {
    if (screenWidth > 1200) return 20;
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 16;
    return 12;
  }

  double _getButtonHeight(double screenWidth) {
    if (screenWidth > 1200) return 60;
    if (screenWidth > 800) return 56;
    if (screenWidth > 600) return 52;
    return 48;
  }
}