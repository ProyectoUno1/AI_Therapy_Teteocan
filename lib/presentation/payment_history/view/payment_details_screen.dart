// lib/presentation/payment_history/views/payment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/payment_history_model.dart';
import 'package:ai_therapy_teteocan/presentation/payment_history/bloc/payment_history_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/payment_history_repository.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsScreen({super.key, required this.paymentId});

  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final Color accentColor = AppConstants.accentColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentHistoryBloc>().add(LoadPaymentDetails(widget.paymentId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detalles del Pago',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
        builder: (context, state) {
          if (state is PaymentDetailsLoading) {
            return _buildLoadingState();
          } else if (state is PaymentHistoryError) {
            return _buildErrorState(state.message);
          } else if (state is PaymentDetailsLoaded) {
            return _buildPaymentDetails(state.paymentDetails);
          }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        
        return Center(
          child: Padding(
            padding: isTablet 
                ? const EdgeInsets.all(48.0)
                : const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline, 
                  size: isTablet ? 80.0 : 64.0, 
                  color: Colors.grey.shade400
                ),
                SizedBox(height: isTablet ? 24.0 : 16.0),
                Text(
                  'Error al cargar detalles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: isTablet ? 20.0 : 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 16.0 : 8.0),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60.0 : 20.0,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 16.0 : 14.0,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 24.0 : 16.0),
                ElevatedButton(
                  onPressed: () {
                    context.read<PaymentHistoryBloc>().add(LoadPaymentDetails(widget.paymentId));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 24.0,
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                  child: Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetails(PaymentDetails payment) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1200;
        final isLandscape = screenHeight < screenWidth;

        return SingleChildScrollView(
          padding: _getAdaptivePadding(screenWidth, isLandscape),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : (isTablet ? 600 : double.infinity),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de resumen
                  _buildSummaryCard(payment, screenWidth),
                  _buildSpacing(24, screenWidth),

                  // Información del pago
                  _buildPaymentInfoSection(payment, screenWidth),
                  _buildSpacing(24, screenWidth),

                  // Acciones
                  if (payment.status == PaymentStatus.failed)
                    _buildRetryButton(payment, screenWidth),
                  
                  _buildSpacing(20, screenWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ PADDING ADAPTATIVO
  EdgeInsets _getAdaptivePadding(double screenWidth, bool isLandscape) {
    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    } else if (screenWidth > 800) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    } else if (screenWidth > 600) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return isLandscape
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  // ✅ ESPACIADO ADAPTATIVO
  Widget _buildSpacing(double baseHeight, double screenWidth) {
    final multiplier = screenWidth > 1200 ? 1.2 : (screenWidth > 600 ? 1.0 : 0.8);
    return SizedBox(height: baseHeight * multiplier);
  }

  // ✅ TARJETA DE RESUMEN - CORREGIDA
  Widget _buildSummaryCard(PaymentDetails payment, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
      ),
      child: Padding(
        padding: _getCardPadding(screenWidth),
        child: Column(
          children: [
            _buildSummaryRow(
              'Monto',
              payment.formattedAmount,
              _getStatusColor(payment.status),
              screenWidth,
              isAmount: true,
            ),
            _buildSpacing(16, screenWidth),
            _buildStatusRow(payment.status, screenWidth),
            _buildSpacing(8, screenWidth),
            _buildSummaryRow(
              'Fecha',
              payment.date != null ? _formatDetailedDate(payment.date!) : 'Sin fecha',
              Colors.grey.shade600,
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ROW DE RESUMEN CORREGIDO
  Widget _buildSummaryRow(String label, String value, Color valueColor, double screenWidth, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // ✅ AÑADIDO EXPANDED
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: _getBodyTextSize(screenWidth),
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded( // ✅ AÑADIDO EXPANDED
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isAmount ? _getTitleSize(screenWidth) : _getBodyTextSize(screenWidth),
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ✅ ROW DE ESTADO CORREGIDO
  Widget _buildStatusRow(PaymentStatus status, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // ✅ AÑADIDO EXPANDED
          flex: 2,
          child: Text(
            'Estado',
            style: TextStyle(
              fontSize: _getBodyTextSize(screenWidth),
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded( // ✅ AÑADIDO EXPANDED
          flex: 3,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getSpacing(screenWidth),
              vertical: _getSpacing(screenWidth) * 0.6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(status),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getSmallTextSize(screenWidth),
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ SECCIÓN DE INFORMACIÓN DEL PAGO
  Widget _buildPaymentInfoSection(PaymentDetails payment, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMACIÓN DEL PAGO',
          style: TextStyle(
            fontSize: _getSmallTextSize(screenWidth),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        _buildSpacing(12, screenWidth),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
          child: Padding(
            padding: _getCardPadding(screenWidth),
            child: Column(
              children: [
                _buildDetailRow('Descripción', payment.description, screenWidth),
                _buildDetailRow('Método de pago', payment.paymentMethod.toUpperCase(), screenWidth),
                if (payment.psychologistName != null)
                  _buildDetailRow('Psicólogo', payment.psychologistName!, screenWidth),
                if (payment.sessionDate != null && payment.sessionTime != null)
                  _buildDetailRow(
                    'Fecha y hora',
                    '${payment.sessionDate!} a las ${payment.sessionTime!}',
                    screenWidth,
                  ),
                if (payment.paymentIntentId != null)
                  _buildDetailRow(
                    'ID de transacción',
                    payment.paymentIntentId!,
                    screenWidth,
                    canCopy: true,
                  ),
                if (payment.customerId != null)
                  _buildDetailRow(
                    'ID de cliente',
                    payment.customerId!,
                    screenWidth,
                    canCopy: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ ROW DE DETALLE CORREGIDO - ESTA ES LA LÍNEA 228
  Widget _buildDetailRow(String label, String value, double screenWidth, {bool canCopy = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getSpacing(screenWidth)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: screenWidth > 600 ? 2 : 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _getBodyTextSize(screenWidth),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: _getSpacing(screenWidth)),
          Expanded(
            flex: screenWidth > 600 ? 3 : 4,
            child: Row(
              children: [
                Expanded( // ✅ AÑADIDO EXPANDED PARA EL TEXTO
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: _getBodyTextSize(screenWidth),
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy) ...[
                  SizedBox(width: _getSpacing(screenWidth)),
                  GestureDetector(
                    onTap: () {
                      // Aquí iría la lógica para copiar al portapapeles
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copiado al portapapeles',
                            style: TextStyle(
                              fontSize: _getBodyTextSize(screenWidth),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.content_copy,
                      size: _getIconSize(screenWidth),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BOTÓN DE REINTENTO
  Widget _buildRetryButton(PaymentDetails payment, double screenWidth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showRetryPaymentDialog(payment, screenWidth);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: _getButtonHeight(screenWidth)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
        ),
        child: Text(
          'Reintentar Pago',
          style: TextStyle(
            fontSize: _getBodyTextSize(screenWidth),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ✅ DIÁLOGO DE REINTENTO DE PAGO - CORREGIDO
  void _showRetryPaymentDialog(PaymentDetails payment, double screenWidth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  'Reintentar Pago',
                  style: TextStyle(
                    fontSize: _getTitleSize(screenWidth),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                _buildSpacing(16, screenWidth),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _getSpacing(screenWidth)),
                  child: Text(
                    '¿Deseas reintentar el pago de ${payment.formattedAmount}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _getBodyTextSize(screenWidth),
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildSpacing(24, screenWidth),
                Row(
                  children: [
                    Expanded( // ✅ AÑADIDO EXPANDED
                      child: TextButton(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: _getBodyTextSize(screenWidth),
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: _getSpacing(screenWidth)),
                    Expanded( // ✅ AÑADIDO EXPANDED
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Funcionalidad de reintento en desarrollo',
                                style: TextStyle(
                                  fontSize: _getBodyTextSize(screenWidth),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Reintentar',
                          style: TextStyle(
                            fontSize: _getBodyTextSize(screenWidth),
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  // ✅ FUNCIONES DE TAMAÑO ADAPTATIVAS
  double _getTitleSize(double screenWidth) {
    if (screenWidth > 1200) return 24;
    if (screenWidth > 800) return 22;
    if (screenWidth > 600) return 20;
    return 18;
  }

  double _getBodyTextSize(double screenWidth) {
    if (screenWidth > 1200) return 16;
    if (screenWidth > 800) return 15;
    if (screenWidth > 600) return 14;
    return 13;
  }

  double _getSmallTextSize(double screenWidth) {
    if (screenWidth > 1200) return 14;
    if (screenWidth > 800) return 13;
    if (screenWidth > 600) return 12;
    return 11;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth > 1200) return 20;
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 16;
    return 14;
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
    if (screenWidth > 1200) return 18;
    if (screenWidth > 800) return 16;
    if (screenWidth > 600) return 14;
    return 12;
  }

  // ✅ FUNCIONES AUXILIARES
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}