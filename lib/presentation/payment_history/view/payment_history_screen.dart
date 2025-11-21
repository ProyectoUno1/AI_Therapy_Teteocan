// lib/presentation/payment_history/views/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/payment_history_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/payment_history_repository.dart';
import 'package:ai_therapy_teteocan/presentation/payment_history/bloc/payment_history_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/payment_history/view/payment_details_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final Color accentColor = AppConstants.accentColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Historial de Pagos',
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
          if (state is PaymentHistoryLoading) {
            return _buildLoadingState();
          } else if (state is PaymentHistoryError) {
            return _buildErrorState(state.message);
          } else if (state is PaymentHistoryLoaded) {
            return _buildPaymentsList(state.payments);
          }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
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
                  Icons.sentiment_dissatisfied, 
                  size: isTablet ? 80.0 : 64.0, 
                  color: Colors.red.shade400
                ),
                SizedBox(height: isTablet ? 24.0 : 16.0),
                Text(
                  'No pudimos cargar tu historial',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: isTablet ? 12.0 : 8.0),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60.0 : 20.0,
                  ),
                  child: Text(
                    message.contains('Exception: ') ? message.split('Exception: ')[1] : message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 24.0 : 16.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40.0 : 30.0,
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                  onPressed: () {
                    context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
                  },
                  child: Text(
                    'Reintentar', 
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      fontFamily: 'Poppins'
                    )
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList(List<PaymentRecord> payments) {
    if (payments.isEmpty) {
      return _buildEmptyState('Aún no tienes pagos registrados.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1200;
        final isLandscape = screenHeight < screenWidth;

        return RefreshIndicator(
          color: accentColor,
          onRefresh: () async {
            context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
          },
          child: Padding(
            padding: _getAdaptivePadding(screenWidth, isLandscape),
            child: _buildPaymentsGrid(payments, screenWidth, isDesktop),
          ),
        );
      },
    );
  }

  // ✅ LAYOUT ADAPTATIVO PARA LISTA/GRID
  Widget _buildPaymentsGrid(List<PaymentRecord> payments, double screenWidth, bool isDesktop) {
    if (isDesktop) {
      // Desktop: Grid de 2 columnas
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _getSpacing(screenWidth),
          mainAxisSpacing: _getSpacing(screenWidth),
          childAspectRatio: 1.8,
        ),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          return _buildPaymentCard(payments[index], screenWidth);
        },
      );
    } else if (screenWidth > 600) {
      // Tablet: Lista con más espaciado
      return ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: _getSpacing(screenWidth)),
            child: _buildPaymentCard(payments[index], screenWidth),
          );
        },
      );
    } else {
      // Móvil: Lista normal
      return ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: _getSpacing(screenWidth)),
            child: _buildPaymentCard(payments[index], screenWidth),
          );
        },
      );
    }
  }

  Widget _buildEmptyState(String message) {
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
                  Icons.receipt_long, 
                  size: isTablet ? 80.0 : 64.0, 
                  color: Colors.grey.shade400
                ),
                SizedBox(height: isTablet ? 24.0 : 16.0),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    color: Colors.grey.shade600, 
                    fontFamily: 'Poppins'
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment, double screenWidth) {
    final IconData icon = payment.type == PaymentType.psychologySession
        ? Icons.psychology_alt 
        : Icons.workspace_premium;
    final Color statusColor = _getStatusColor(payment.status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(paymentId: payment.id),
            ),
          );
        },
        child: Padding(
          padding: _getCardPadding(screenWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono y descripción
              Row(
                children: [
                  Container(
                    width: _getIconContainerSize(screenWidth),
                    height: _getIconContainerSize(screenWidth),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth) * 0.7),
                    ),
                    child: Icon(
                      icon, 
                      color: statusColor, 
                      size: _getIconSize(screenWidth)
                    ),
                  ),
                  SizedBox(width: _getSpacing(screenWidth)),
                  Expanded(
                    child: Text(
                      payment.description,
                      style: TextStyle(
                        fontSize: _getBodyTextSize(screenWidth),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios, 
                    size: _getIconSize(screenWidth), 
                    color: Colors.grey.shade400
                  ),
                ],
              ),
              
              SizedBox(height: _getSpacing(screenWidth)),
              
              Divider(
                height: 1, 
                thickness: 0.5, 
                color: Colors.grey.shade300
              ),
              
              SizedBox(height: _getSpacing(screenWidth)),

              // Información del pago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de ${payment.type == PaymentType.subscription ? 'Pago' : 'Cita'}:',
                          style: TextStyle(
                            color: Colors.grey.shade600, 
                            fontSize: _getSmallTextSize(screenWidth)
                          ),
                        ),
                        SizedBox(height: _getSpacing(screenWidth) * 0.5),
                        Text(
                          _formatDate(payment.date),
                          style: TextStyle(
                            fontSize: _getBodyTextSize(screenWidth),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (payment.psychologistName != null && payment.type == PaymentType.psychologySession)
                          Padding(
                            padding: EdgeInsets.only(top: _getSpacing(screenWidth) * 0.5),
                            child: Text(
                              'Psicólogo: ${payment.psychologistName!}',
                              style: TextStyle(
                                fontSize: _getSmallTextSize(screenWidth),
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Monto y Estado
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        payment.formattedAmount,
                        style: TextStyle(
                          fontSize: _getBodyTextSize(screenWidth),
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: _getSpacing(screenWidth) * 0.5),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getSpacing(screenWidth) * 0.8,
                          vertical: _getSpacing(screenWidth) * 0.4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth) * 0.6),
                        ),
                        child: Text(
                          payment.statusText.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: _getSmallTextSize(screenWidth),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FUNCIONES DE TAMAÑO ADAPTATIVAS
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
    if (screenWidth > 1200) return 24;
    if (screenWidth > 800) return 22;
    if (screenWidth > 600) return 20;
    return 18;
  }

  double _getIconContainerSize(double screenWidth) {
    if (screenWidth > 1200) return 55;
    if (screenWidth > 800) return 50;
    if (screenWidth > 600) return 45;
    return 40;
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
    if (screenWidth > 1200) return const EdgeInsets.all(20);
    if (screenWidth > 800) return const EdgeInsets.all(18);
    if (screenWidth > 600) return const EdgeInsets.all(16);
    return const EdgeInsets.all(14);
  }

  EdgeInsets _getAdaptivePadding(double screenWidth, bool isLandscape) {
    if (screenWidth > 1200) {
      return const EdgeInsets.all(24);
    } else if (screenWidth > 800) {
      return const EdgeInsets.all(20);
    } else if (screenWidth > 600) {
      return const EdgeInsets.all(16);
    } else {
      return isLandscape
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  // ✅ FUNCIONES AUXILIARES
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green.shade600;
      case PaymentStatus.pending:
        return Colors.orange.shade600;
      case PaymentStatus.failed:
        return Colors.red.shade600;
      case PaymentStatus.refunded:
        return Colors.blue.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}