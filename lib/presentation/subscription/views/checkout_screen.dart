// lib/presentation/subscription/views/checkout_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  // Estado para controlar el proceso de pago
  bool _isProcessingPayment = false;

  
  String? _paymentResult; 
  String? _paymentMessage;
  
  // Suscripción para escuchar los deep links
  StreamSubscription<Uri>? _linkSubscription;

  // Instancia para manejar los deep links
  late AppLinks _appLinks;

  
  final String backendUrl =
      'http://10.0.2.2:3000/api/stripe/create-checkout-session';

  @override
  void initState() {
    super.initState();
    // Inicializar el listener de deep links al cargar la pantalla
    _initDeepLinks();
  }

  //  Método para inicializar el listener de deep links
  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Escuchar deep links mientras la app está abierta
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) {
        print(' Error en deep link: $err');
        _setPaymentResult('error', 'Error procesando el resultado del pago');
      },
    );

    //  Manejar cuando la app se abre con un deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _handleDeepLink(initialLink);
        });
      }
    } catch (e) {
      print(' Error obteniendo link inicial: $e');
    }
  }

  // Manejar el deep link recibido
  void _handleDeepLink(Uri uri) {
    
    if (uri.scheme == 'auroraapp') {
      if (uri.host == 'success') {
        final sessionId = uri.queryParameters['session_id'];
        
        if (sessionId != null) {
          _verifyPaymentAndUpdateFirebase(sessionId);
        } else {
          _setPaymentResult('error', 'No se pudo verificar el pago (sin session ID)');
        }
      } else if (uri.host == 'cancel') {
        
        _handlePaymentCancelled();
      }
    }
  }

  //  Verificación y actualización del pago
  Future<void> _verifyPaymentAndUpdateFirebase(String sessionId) async {
    try {
      
      
      _setProcessingState(true);

      // 1. Verificar estado de la sesión en Stripe
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/stripe/verify-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        

        if (data['paymentStatus'] == 'paid') {
          
          await Future.delayed(Duration(seconds: 2)); // Dar tiempo al webhook
          
          _setPaymentResult(
            'success',
            '¡Perfecto! Tu suscripción a ${widget.planName} ha sido activada.',
          );
        } else {
          _setPaymentResult(
            'error', 
            'El pago no se completó correctamente. Estado: ${data['paymentStatus']}'
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _setPaymentResult(
          'error', 
          'Error al verificar el pago: ${errorData['error'] ?? 'Error desconocido'}'
        );
      }
    } catch (e) {
     
      _setPaymentResult('error', 'Error de conexión al verificar el pago');
    } finally {
      _setProcessingState(false);
    }
  }

  // Manejar un pago cancelado
  void _handlePaymentCancelled() {
    _setPaymentResult('error', 'Has cancelado el proceso de pago.');
  }

  @override
  void dispose() {
    // Cancelar la suscripción al deep link para evitar fugas de memoria
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Métodos para actualizar el estado de la pantalla
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
        // Resetear el estado de procesamiento
        _isProcessingPayment = false;
      });
    }
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
            if (_paymentResult != null)
              _buildResultWidget(),
            if (_paymentResult == null) ...[
              _buildSubscriptionSummary(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
              const SizedBox(height: 32),
              _buildCompleteButton(),
            ]
          ],
        ),
      ),
    );
  }

  //   mostrar el resumen de la suscripción
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
                        color: Theme.of(context).textTheme.headlineMedium?.color,
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

  //  mostrar el resumen de la orden
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

  //  botón para completar el pago
  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        // Deshabilitar el botón si el pago está en proceso
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

  //  para iniciar el proceso de pago
  Future<void> _processStripePayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      print('1. Obteniendo datos del usuario autenticado...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setPaymentResult('error', 'Usuario no autenticado. Por favor, inicia sesión.');
        return;
      }

      final String userEmail = user.email!;
      final String userId = user.uid;

      //  Obtener el nombre del usuario desde Firebase
      String? userName;
      try {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(userId)
            .get();
        userName =
            patientDoc.data()?['username'] ?? user.displayName ?? 'Usuario';
      } catch (e) {
        print('No se pudo obtener el nombre del usuario: $e');
        userName = user.displayName ?? 'Usuario';
      }

      print('2. Creando sesión de checkout para: $userEmail');

      final url = Uri.parse(backendUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planId': widget.planId,
          'userEmail': userEmail,
          'userId': userId,
          'userName': userName,
          'planName': widget.planName,
        }),
      );

      if (response.statusCode != 200) {
        print('Error del backend: ${response.body}');
        final errorData = jsonDecode(response.body);

        
        if (errorData['error']?.contains('ya tiene una suscripción') == true) {
          _setPaymentResult(
            'error',
            'Ya tienes una suscripción activa. Ve a la sección de suscripciones para ver los detalles.',
          );
          return;
        }

        throw Exception('Error del servidor: ${response.statusCode}');
      }

      print('3. Respuesta del backend recibida');
      final sessionData = jsonDecode(response.body);
      final String? checkoutUrl = sessionData['checkoutUrl'];

      if (checkoutUrl == null) {
        throw Exception(
          'URL de Checkout no encontrada en la respuesta del servidor.',
        );
      }

      print('4. Abriendo Stripe Checkout...');
      await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error inesperado: $e');
      _setPaymentResult('error', 'Un error inesperado ocurrió: $e');
    }
   
  }

  // Widget para mostrar el resultado del pago
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
              //  Regresar con resultado exitoso para recargar la pantalla anterior
              Navigator.of(context).pop(isSuccess);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
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