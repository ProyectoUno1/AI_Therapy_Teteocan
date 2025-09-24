// lib/presentation/subscription/views/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/services/subscription_service.dart';

// URL de tu servidor de backend
const String backendUrl = 'http://10.0.2.2:3000';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

String _formatDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy');
  return formatter.format(date);
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isLoading = true;
  int aiMessagesUsed = 15;
  int aiMessagesLimit = 20;
  SubscriptionStatus? _subscriptionStatus;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  // Cargar datos de la suscripción desde el backend
  Future<void> _loadSubscriptionData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final status = await SubscriptionService.getUserSubscriptionStatus();
      setState(() {
        _subscriptionStatus = status;
      });
    } catch (e) {
      _showSnackBar("Error al cargar el estado de la suscripción.");
      // print('Error loading subscription data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // FUNCIÓN PARA INICIAR EL PROCESO DE PAGO
  Future<void> _startStripePayment({
    required String planId,
    required String planName,
    required String price,
    required String period,
    bool isAnnual = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Debes iniciar sesión para comprar un plan.");
      return;
    }

    // Verificar si ya tiene suscripción antes de proceder
    if (_subscriptionStatus?.hasSubscription == true) {
      _showSnackBar("Ya tienes una suscripción activa.");
      return;
    }

    // print('🚀 Navegando al checkout...');

    // Navegación temporal mientras no existe CheckoutScreen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Checkout')),
          body: Center(child: Text('Checkout no implementado')),
        ),
      ),
    );
    await _loadSubscriptionData();
  }

  // FUNCIÓN PARA CANCELAR LA SUSCRIPCIÓN
  Future<void> _cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Error: Usuario no autenticado.");
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cancelar Suscripción',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            '¿Estás seguro de que quieres cancelar tu suscripción? Se mantendrá activa hasta el final del periodo actual.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text(
                'Sí, Cancelar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await SubscriptionService.cancelSubscription();
      if (result.success) {
        _showSnackBar("Suscripción cancelada exitosamente.");
      } else {
        _showSnackBar("Error al cancelar la suscripción: ${result.message}");
      }
    } catch (e) {
      _showSnackBar("Hubo un error al procesar la cancelación.");
      // print('Error canceling subscription: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      _loadSubscriptionData();
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // CONSTRUIR LA INTERFAZ DINÁMICAMENTE
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  MOSTRAR ESTADO DE SUSCRIPCIÓN ACTIVA
                  if (_subscriptionStatus != null &&
                      _subscriptionStatus!.hasSubscription)
                    _buildActiveSubscriptionCard()
                  else ...[
                    //  MOSTRAR PLAN GRATUITO Y OPCIONES DE UPGRADE
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 30),
                    _buildPremiumFeatures(),
                    const Spacer(),
                    _buildPricingSection(),
                    const SizedBox(height: 20),
                    _buildUpgradeButton(),
                  ],
                ],
              ),
            ),
    );
  }

  // TARJETA PARA MOSTRAR SUSCRIPCIÓN ACTIVA
  Widget _buildActiveSubscriptionCard() {
    final subscription = _subscriptionStatus!.subscription!;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la suscripción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Suscripción Activa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subscription.planName ?? 'Plan Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${subscription.status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
                if (subscription.currentPeriodEnd != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expira: ${_formatDate(subscription.currentPeriodEnd!)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detalles de la suscripción
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles de tu suscripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow('Plan', subscription.planName ?? 'Premium'),
                  _buildDetailRow('Estado', subscription.status.toUpperCase()),
                  if (subscription.userEmail != null)
                    _buildDetailRow('Email', subscription.userEmail!),
                  if (subscription.currentPeriodEnd != null)
                    _buildDetailRow(
                      'Próxima facturación',
                      _formatDate(subscription.currentPeriodEnd!),
                    ),

                  const SizedBox(height: 20),

                  // Beneficios activos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Beneficios activos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitItem('Conversaciones ilimitadas con IA'),
                        _buildBenefitItem('Análisis emocional avanzado'),
                        _buildBenefitItem('Seguimiento de progreso'),
                        _buildBenefitItem('Soporte prioritario'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botón de cancelar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cancelSubscription,
                      icon: Icon(Icons.cancel_outlined),
                      label: Text(
                        'Cancelar Suscripción',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Text(
            benefit,
            style: TextStyle(
              fontSize: 13,
              color: Colors.green[700],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final usagePercentage = aiMessagesUsed / aiMessagesLimit;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Plan Gratuito',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mensajes con IA',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '$aiMessagesUsed/$aiMessagesLimit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: usagePercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            'Hoy has usado $aiMessagesUsed de $aiMessagesLimit mensajes con IA disponibles',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.color,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$9.99',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '/mes',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Cancela cuando quieras • Sin compromisos',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showPricingPlans(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 20),
            SizedBox(width: 8),
            Text(
              'Actualizar a Premium',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPricingPlans() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPricingModal(),
    );
  }

  Widget _buildPricingModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Elige tu plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlanOption(
                    title: 'Plan Mensual',
                    subtitle: 'Perfecto para empezar',
                    price: '\$9.99',
                    period: '/mes',
                    isPopular: false,
                    onTap: () {
                      Navigator.pop(context);
                      _startStripePayment(
                        planId: 'price_1RvpKc2Szsvtfc49E0VZHcAv',
                        planName: 'Premium Mensual',
                        price: '\$9.99',
                        period: '/mes',
                        isAnnual: false,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    title: 'Plan Anual',
                    subtitle: '2 meses gratis',
                    price: '\$99.99',
                    period: '/año',
                    originalPrice: '\$119.88',
                    isPopular: true,
                    onTap: () {
                      Navigator.pop(context);
                      _startStripePayment(
                        planId: 'price_1RwQDS2Szsvtfc49voxyVem6',
                        planName: 'Premium Anual',
                        price: '\$99.99',
                        period: '/año',
                        isAnnual: true,
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Al suscribirte, aceptas nuestros términos y condiciones. Tu suscripción se renovará automáticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontFamily: 'Poppins',
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

  Widget _buildPlanOption({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required bool isPopular,
    required VoidCallback onTap,
    String? originalPrice,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPopular
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'MEJOR VALOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular) const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (originalPrice != null) ...[
                            Text(
                              originalPrice,
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isPopular
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).textTheme.headlineMedium?.color,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                period,
                                style: TextStyle(
                                  fontSize: 12,
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        foregroundColor: isPopular
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        side: !isPopular
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Seleccionar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
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
