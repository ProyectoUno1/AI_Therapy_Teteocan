// lib/presentation/subscription/views/subscription_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';
import 'package:ai_therapy_teteocan/data/repositories/subscription_repository.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/checkout_screen.dart';
import 'package:ai_therapy_teteocan/data/models/plan_model.dart';
import 'package:ai_therapy_teteocan/core/services/plans_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/ai_usage_limit_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubscriptionBloc(repository: SubscriptionRepositoryImpl())
            ..add(LoadSubscriptionStatus()),
      child: const SubscriptionView(),
    );
  }
}

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  int aiMessagesUsed = 0;
  int aiMessagesLimit = 20;
  late SubscriptionBloc _subscriptionBloc;

  final PlansService _plansService = PlansService();
  List<PlanModel> _availablePlans = [];
  bool _isLoadingPlans = false;
  String? _plansError;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = BlocProvider.of<SubscriptionBloc>(context);
    _loadAvailablePlans();
    _startListeningToUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              final data = snapshot.data()!;
              setState(() {
                aiMessagesUsed = data['messageCount'] ?? 0;
                _isPremium = data['isPremium'] == true;
                aiMessagesLimit = _isPremium ? 99999 : 20;
              });
            }
          });
    }
  }

  Future<void> _loadAvailablePlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final plans = await _plansService.getAvailablePlans();
      setState(() {
        _availablePlans = plans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _plansError = e.toString();
        _isLoadingPlans = false;
        _availablePlans = _getDefaultPlans();
      });
    }
  }

  List<PlanModel> _getDefaultPlans() {
    return [
      const PlanModel(
        id: 'price_1RvpKc2Szsvtfc49E0VZHcAv',
        productId: 'prod_default_monthly',
        productName: 'Premium',
        planName: 'Premium Mensual',
        amount: 49900,
        currency: 'mxn',
        interval: 'month',
        intervalCount: 1,
        displayPrice: '\$499.00',
        isAnnual: false,
      ),
      const PlanModel(
        id: 'price_1RwQDS2Szsvtfc49voxyVem6',
        productId: 'prod_default_annual',
        productName: 'Premium',
        planName: 'Premium Anual',
        amount: 199900,
        currency: 'mxn',
        interval: 'year',
        intervalCount: 1,
        displayPrice: '\$1999.00',
        isAnnual: true,
      ),
    ];
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  void _navigateToCheckoutScreen({
    required String planId,
    required String planName,
    required String price,
    required String period,
    required bool isAnnual,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          planName: planName,
          price: price,
          period: period,
          planId: planId,
          isAnnual: isAnnual,
          subscriptionBloc: _subscriptionBloc,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        title: Text(
          'Suscripciones',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontSize: _getAdaptiveTextSize(
              MediaQuery.of(context).size.width,
              baseSize: 18,
            ),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CheckoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (state is PaymentVerificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _subscriptionBloc.add(LoadSubscriptionStatus());
          } else if (state is SubscriptionCancellationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final orientation = MediaQuery.of(context).orientation;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: _getAdaptivePadding(screenWidth, orientation),
                child: _buildContent(
                  state,
                  screenWidth,
                  screenHeight,
                  orientation,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ CONTENIDO PRINCIPAL SIMPLIFICADO
  Widget _buildContent(
    SubscriptionState state,
    double screenWidth,
    double screenHeight,
    Orientation orientation,
  ) {
    if (state is SubscriptionLoaded && state.hasActiveSubscription) {
      return _buildActiveSubscriptionCard(state.subscriptionData!, screenWidth);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCurrentPlanCard(screenWidth),
        _buildSpacing(30, screenWidth),
        _buildPremiumFeatures(screenWidth),
        _buildSpacing(30, screenWidth),
        _buildDynamicPricingSection(screenWidth),
        _buildSpacing(20, screenWidth),
        _buildUpgradeButton(context, state, screenWidth),
        _buildSpacing(20, screenWidth),
      ],
    );
  }

  // ✅ PADDING ADAPTATIVO
  EdgeInsets _getAdaptivePadding(double screenWidth, Orientation orientation) {
    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 24);
    } else if (screenWidth > 800) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 20);
    } else if (screenWidth > 600) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return orientation == Orientation.portrait
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  // ✅ ESPACIADO ADAPTATIVO
  Widget _buildSpacing(double baseHeight, double screenWidth) {
    final multiplier = screenWidth > 1200
        ? 1.2
        : (screenWidth > 600 ? 1.0 : 0.8);
    return SizedBox(height: baseHeight * multiplier);
  }

  // ✅ MÉTODO MEJORADO PARA TAMAÑOS DE TEXTO ADAPTATIVOS
  double _getAdaptiveTextSize(double screenWidth, {required double baseSize}) {
    if (screenWidth > 1200) return baseSize * 1.3; // Desktop
    if (screenWidth > 800) return baseSize * 1.15; // Tablet
    if (screenWidth > 600) return baseSize * 1.05; // Tablet pequeña
    return baseSize; // Mobile
  }

  // ✅ SECCIÓN DE PRECIOS DINÁMICA MEJORADA
  // ✅ CORRIGE EL MÉTODO _buildDynamicPricingSection - BUSCA Y REEMPLAZA
  Widget _buildDynamicPricingSection(double screenWidth) {
    final monthlyPlan = _availablePlans
        .where((plan) => !plan.isAnnual)
        .firstOrNull;

    if (monthlyPlan == null) {
      return _buildStaticPricingSection(screenWidth);
    }

    return Column(
      children: [
        // ✅ ROW CORREGIDO CON EXPANDED
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              // ✅ AÑADIDO EXPANDED
              child: Text(
                monthlyPlan.displayPrice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 24),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/${monthlyPlan.interval ?? 'mes'}',
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        _buildSpacing(8, screenWidth),
        Text(
          'Cancela cuando quieras • Sin compromisos',
          style: TextStyle(
            fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 12),
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStaticPricingSection(double screenWidth) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$499.00',
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 24),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/mes',
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        _buildSpacing(8, screenWidth),
        Text(
          'Cancela cuando quieras • Sin compromisos',
          style: TextStyle(
            fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 12),
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ TARJETA DE SUSCRIPCIÓN ACTIVA SIMPLIFICADA
  Widget _buildActiveSubscriptionCard(
    SubscriptionData subscription,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta superior con gradiente - ✅ ROW CORREGIDO
        Container(
          width: double.infinity,
          padding: _getCardPadding(screenWidth),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor,
                AppConstants.primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: _getIconSize(screenWidth),
                  ),
                  SizedBox(width: _getSpacing(screenWidth)),
                  Expanded(
                    // ✅ AÑADIDO EXPANDED
                    child: Text(
                      'Suscripción Activa',
                      style: TextStyle(
                        fontSize: _getAdaptiveTextSize(
                          screenWidth,
                          baseSize: 16,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              _buildSpacing(16, screenWidth),
              Text(
                subscription.planName ?? 'Plan Premium',
                style: TextStyle(
                  fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              _buildSpacing(8, screenWidth),
              Text(
                'Estado: ${subscription.status.toUpperCase()}',
                style: TextStyle(
                  fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Poppins',
                ),
              ),
              if (subscription.currentPeriodEnd != null) ...[
                _buildSpacing(4, screenWidth),
                Text(
                  'Expira: ${_formatDate(subscription.currentPeriodEnd!)}',
                  style: TextStyle(
                    fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildSpacing(20, screenWidth),

        // Tarjeta de detalles
        Container(
          width: double.infinity,
          padding: _getCardPadding(screenWidth),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles de tu suscripción',
                style: TextStyle(
                  fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 16),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              _buildSpacing(20, screenWidth),
              _buildDetailRow(
                'Plan',
                subscription.planName ?? 'Premium',
                screenWidth,
              ),
              _buildDetailRow(
                'Estado',
                subscription.status.toUpperCase(),
                screenWidth,
              ),
              if (subscription.userEmail != null)
                _buildDetailRow('Email', subscription.userEmail!, screenWidth),
              if (subscription.currentPeriodEnd != null)
                _buildDetailRow(
                  'Próxima facturación',
                  _formatDate(subscription.currentPeriodEnd!),
                  screenWidth,
                ),
              _buildSpacing(20, screenWidth),

              // Beneficios
              Container(
                padding: EdgeInsets.all(_getSpacing(screenWidth)),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ ROW CORREGIDO
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.green[700],
                          size: _getIconSize(screenWidth),
                        ),
                        SizedBox(width: _getSpacing(screenWidth)),
                        Expanded(
                          // ✅ AÑADIDO EXPANDED
                          child: Text(
                            'Beneficios activos',
                            style: TextStyle(
                              fontSize: _getAdaptiveTextSize(
                                screenWidth,
                                baseSize: 14,
                              ),
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    _buildSpacing(8, screenWidth),
                    _buildBenefitItem(
                      'Conversaciones ilimitadas con IA',
                      screenWidth,
                    ),
                    _buildBenefitItem(
                      'Análisis emocional avanzado',
                      screenWidth,
                    ),
                    _buildBenefitItem('Seguimiento de progreso', screenWidth),
                    _buildBenefitItem('Soporte prioritario', screenWidth),
                  ],
                ),
              ),
              _buildSpacing(20, screenWidth),

              // Botón de cancelación
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state is SubscriptionCancellationInProgress
                          ? null
                          : () => _showCancelConfirmation(context, screenWidth),
                      icon: state is SubscriptionCancellationInProgress
                          ? SizedBox(
                              width: _getIconSize(screenWidth),
                              height: _getIconSize(screenWidth),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.cancel_outlined,
                              size: _getIconSize(screenWidth),
                            ),
                      label: Text(
                        state is SubscriptionCancellationInProgress
                            ? 'Cancelando...'
                            : 'Cancelar Suscripción',
                        style: TextStyle(
                          fontSize: _getAdaptiveTextSize(
                            screenWidth,
                            baseSize: 14,
                          ),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[200]!),
                        padding: EdgeInsets.symmetric(
                          vertical: _getButtonHeight(screenWidth),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(screenWidth),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ TARJETA DE PLAN ACTUAL MEJORADA
  // ✅ CORRIGE EL MÉTODO _buildCurrentPlanCard - BUSCA Y REEMPLAZA
  Widget _buildCurrentPlanCard(double screenWidth) {
    final usagePercentage = aiMessagesUsed / aiMessagesLimit;

    return Container(
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ ROW CORREGIDO CON EXPANDED
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpacing(screenWidth)),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.grey[600],
                  size: _getIconSize(screenWidth),
                ),
              ),
              SizedBox(width: _getSpacing(screenWidth)),
              Expanded(
                // ✅ AÑADIDO EXPANDED
                child: Text(
                  'Plan Gratuito',
                  style: TextStyle(
                    fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 16),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          _buildSpacing(20, screenWidth),

          // ✅ CONTADOR DE MENSAJES CORREGIDO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // ✅ AÑADIDO EXPANDED
                child: Text(
                  'Mensajes con IA',
                  style: TextStyle(
                    fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                // ✅ ESTE NO NECESITA EXPANDED PORQUE ES CORTO
                '$aiMessagesUsed/$aiMessagesLimit',
                style: TextStyle(
                  fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          _buildSpacing(12, screenWidth),
          LinearProgressIndicator(
            value: usagePercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.primaryColor,
            ),
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
            minHeight: 8,
          ),
          _buildSpacing(16, screenWidth),
          Text(
            'Hoy has usado $aiMessagesUsed de $aiMessagesLimit mensajes con IA disponibles',
            style: TextStyle(
              fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 12),
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ CARACTERÍSTICAS PREMIUM
  // ✅ CORRIGE EL MÉTODO _buildPremiumFeatures - BUSCA Y REEMPLAZA
  Widget _buildPremiumFeatures(double screenWidth) {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Conversaciones ilimitadas',
        'description': 'Chatea con Aurora IA sin restricciones',
      },
      {
        'icon': Icons.psychology,
        'title': 'Análisis emocional avanzado',
        'description': 'Insights profundos sobre tu bienestar mental',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Seguimiento de progreso',
        'description': 'Monitorea tu evolución emocional',
      },
      {
        'icon': Icons.priority_high,
        'title': 'Soporte prioritario',
        'description': 'Atención preferencial y respuesta rápida',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué incluye Premium?',
          style: TextStyle(
            fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 16),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontFamily: 'Poppins',
          ),
        ),
        _buildSpacing(16, screenWidth),
        ...features
            .map(
              (feature) => Padding(
                padding: EdgeInsets.only(bottom: _getSpacing(screenWidth)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(_getSpacing(screenWidth)),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: AppConstants.primaryColor,
                        size: _getIconSize(screenWidth),
                      ),
                    ),
                    SizedBox(width: _getSpacing(screenWidth)),
                    Expanded(
                      // ✅ AÑADIDO EXPANDED
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: _getAdaptiveTextSize(
                                screenWidth,
                                baseSize: 14,
                              ),
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.color,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildSpacing(4, screenWidth),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              fontSize: _getAdaptiveTextSize(
                                screenWidth,
                                baseSize: 12,
                              ),
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  // ✅ BOTÓN DE ACTUALIZACIÓN
  Widget _buildUpgradeButton(
    BuildContext context,
    SubscriptionState state,
    double screenWidth,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is CheckoutInProgress
            ? null
            : () => _showPricingPlans(context, screenWidth),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: _getButtonHeight(screenWidth),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
          elevation: 0,
        ),
        child: state is CheckoutInProgress
            ? SizedBox(
                width: _getIconSize(screenWidth),
                height: _getIconSize(screenWidth),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch, size: _getIconSize(screenWidth)),
                  SizedBox(width: _getSpacing(screenWidth)),
                  Text(
                    'Actualizar a Premium',
                    style: TextStyle(
                      fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ WIDGETS AUXILIARES MEJORADOS
  // ✅ MÉTODO _buildDetailRow CORREGIDO - REEMPLAZA EL ACTUAL
  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getSpacing(screenWidth) / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label - Ocupa el 40% del espacio
          Expanded(
            flex: 4, // 40%
            child: Text(
              label,
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: _getSpacing(screenWidth)),

          // Value - Ocupa el 60% del espacio
          Expanded(
            flex: 6, // 60%
            child: Text(
              value,
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            color: Colors.green[700],
            size: _getIconSize(screenWidth),
          ),
          SizedBox(width: _getSpacing(screenWidth)),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 12),
                color: Colors.green[700],
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FUNCIONES DE TAMAÑO ADAPTATIVAS
  double _getIconSize(double screenWidth) {
    if (screenWidth > 1200) return 24;
    if (screenWidth > 800) return 22;
    if (screenWidth > 600) return 20;
    return 18;
  }

  double _getBorderRadius(double screenWidth) {
    if (screenWidth > 1200) return 20;
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 16;
    return 14;
  }

  double _getSpacing(double screenWidth) {
    if (screenWidth > 1200) return 16;
    if (screenWidth > 800) return 14;
    if (screenWidth > 600) return 12;
    return 10;
  }

  EdgeInsets _getCardPadding(double screenWidth) {
    if (screenWidth > 1200) return const EdgeInsets.all(24);
    if (screenWidth > 800) return const EdgeInsets.all(20);
    if (screenWidth > 600) return const EdgeInsets.all(18);
    return const EdgeInsets.all(16);
  }

  double _getButtonHeight(double screenWidth) {
    if (screenWidth > 1200) return 20;
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 16;
    return 14;
  }

  // ✅ DIÁLOGO DE CONFIRMACIÓN DE CANCELACIÓN
  void _showCancelConfirmation(BuildContext context, double screenWidth) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
          child: Padding(
            padding: _getCardPadding(screenWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cancelar Suscripción',
                  style: TextStyle(
                    fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                _buildSpacing(16, screenWidth),
                Text(
                  '¿Estás seguro de que quieres cancelar tu suscripción? Se mantendrá activa hasta el final del period actual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 14),
                    fontFamily: 'Poppins',
                  ),
                ),
                _buildSpacing(24, screenWidth),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: Text(
                          'No',
                          style: TextStyle(
                            fontSize: _getAdaptiveTextSize(
                              screenWidth,
                              baseSize: 14,
                            ),
                            color: AppConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    SizedBox(width: _getSpacing(screenWidth)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _subscriptionBloc.add(CancelSubscription());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Sí, Cancelar',
                          style: TextStyle(
                            fontSize: _getAdaptiveTextSize(
                              screenWidth,
                              baseSize: 14,
                            ),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ MODAL DE PLANES DE PRECIOS
  void _showPricingPlans(BuildContext context, double screenWidth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDynamicPricingModal(screenWidth),
    );
  }

  Widget _buildDynamicPricingModal(double screenWidth) {
    final modalHeight = screenWidth > 600 ? 0.7 : 0.8;

    return Container(
      height: MediaQuery.of(context).size.height * modalHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: _getCardPadding(screenWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpacing(10, screenWidth),
                  Text(
                    'Elige tu plan',
                    style: TextStyle(
                      fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 16),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  _buildSpacing(20, screenWidth),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availablePlans.length,
                      itemBuilder: (context, index) {
                        final plan = _availablePlans[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: _getSpacing(screenWidth),
                          ),
                          child: _buildDynamicPlanOption(plan, screenWidth),
                        );
                      },
                    ),
                  ),
                  _buildSpacing(16, screenWidth),
                  Center(
                    child: Text(
                      'Al suscribirte, aceptas nuestros términos y condiciones. Tu suscripción se renovará automáticamente.',
                      style: TextStyle(
                        fontSize: _getAdaptiveTextSize(
                          screenWidth,
                          baseSize: 12,
                        ),
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRIGE EL MÉTODO _buildDynamicPlanOption - BUSCA Y REEMPLAZA COMPLETAMENTE
  Widget _buildDynamicPlanOption(PlanModel plan, double screenWidth) {
    final isPopular = plan.isAnnual;

    String? originalPrice;
    String subtitle = plan.isAnnual
        ? '2 meses gratis'
        : 'Perfecto para empezar';

    if (plan.isAnnual) {
      final monthlyEquivalent = (plan.amount * 1.2).round();
      originalPrice = NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
        decimalDigits: 2,
      ).format(monthlyEquivalent / 100);
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _navigateToCheckoutScreen(
          planId: plan.id,
          planName: plan.planName,
          price: plan.displayPrice,
          period: plan.isAnnual ? '/año' : '/mes',
          isAnnual: plan.isAnnual,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          border: Border.all(
            color: isPopular ? AppConstants.primaryColor : Colors.grey[300]!,
            width: isPopular ? 2 : 1,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'MEJOR VALOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getAdaptiveTextSize(screenWidth, baseSize: 10),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Padding(
              padding: _getCardPadding(screenWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular) _buildSpacing(12, screenWidth),

                  // ✅ ROW PRINCIPAL CORREGIDO - ESTA ES PROBABLEMENTE LA LÍNEA 553
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna izquierda - Información del plan
                      Expanded(
                        flex: 6, // 60% del espacio
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.planName,
                              style: TextStyle(
                                fontSize: _getAdaptiveTextSize(
                                  screenWidth,
                                  baseSize: 14,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            _buildSpacing(4, screenWidth),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: _getAdaptiveTextSize(
                                  screenWidth,
                                  baseSize: 12,
                                ),
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: _getSpacing(screenWidth)),

                      // Columna derecha - Precios
                      Expanded(
                        flex: 4, // 40% del espacio
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (originalPrice != null) ...[
                              Text(
                                originalPrice,
                                style: TextStyle(
                                  fontSize: _getAdaptiveTextSize(
                                    screenWidth,
                                    baseSize: 10,
                                  ),
                                  decoration: TextDecoration.lineThrough,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // ✅ ROW DE PRECIO CORREGIDO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    plan.displayPrice,
                                    style: TextStyle(
                                      fontSize: _getAdaptiveTextSize(
                                        screenWidth,
                                        baseSize: 16,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: isPopular
                                          ? AppConstants.primaryColor
                                          : Theme.of(
                                              context,
                                            ).textTheme.headlineMedium?.color,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  plan.isAnnual ? '/año' : '/mes',
                                  style: TextStyle(
                                    fontSize: _getAdaptiveTextSize(
                                      screenWidth,
                                      baseSize: 12,
                                    ),
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSpacing(16, screenWidth),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCheckoutScreen(
                          planId: plan.id,
                          planName: plan.planName,
                          price: plan.displayPrice,
                          period: plan.isAnnual ? '/año' : '/mes',
                          isAnnual: plan.isAnnual,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? AppConstants.primaryColor
                            : Colors.transparent,
                        foregroundColor: isPopular
                            ? Colors.white
                            : AppConstants.primaryColor,
                        side: !isPopular
                            ? BorderSide(
                                color: AppConstants.primaryColor,
                                width: 1,
                              )
                            : null,
                        padding: EdgeInsets.symmetric(
                          vertical: _getButtonHeight(screenWidth),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(screenWidth),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Seleccionar',
                        style: TextStyle(
                          fontSize: _getAdaptiveTextSize(
                            screenWidth,
                            baseSize: 14,
                          ),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
