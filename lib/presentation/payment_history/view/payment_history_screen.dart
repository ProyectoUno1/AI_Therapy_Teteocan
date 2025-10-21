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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tu historial',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message.contains('Exception: ') ? message.split('Exception: ')[1] : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
              },
              child: const Text('Reintentar', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(List<PaymentRecord> payments) {
    if (payments.isEmpty) {
      return _buildEmptyState('Aún no tienes pagos registrados.');
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () async {
        context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentDetailsScreen(paymentId: payment.id),
                ),
              );
            },
            child: _buildPaymentCard(payment),
          );
        },
      ),
    );
  }


  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment) {
    final IconData icon = payment.type == PaymentType.psychologySession
        ? Icons.psychology_alt 
        : Icons.workspace_premium; 
    final Color statusColor = _getStatusColor(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Descripción Principal
                Expanded(
                  child: Text(
                    payment.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Flecha de Detalle
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de ${payment.type == PaymentType.subscription ? 'Pago' : 'Cita'}:',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(payment.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                    ),
                    if (payment.psychologistName != null && payment.type == PaymentType.psychologySession)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Psicólogo: ${payment.psychologistName!}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                  ],
                ),
                // Monto y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      payment.formattedAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Poppins',
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment.statusText.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 10,
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
    );
  }

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