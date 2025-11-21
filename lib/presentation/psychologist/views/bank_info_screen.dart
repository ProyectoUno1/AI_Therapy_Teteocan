// lib/presentation/psychologist/views/bank_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/bank_info_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/bank_info_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/bank_info_state.dart';
import 'dart:convert';

class BankInfoScreen extends StatefulWidget {
  const BankInfoScreen({super.key});

  @override
  _BankInfoScreenState createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends State<BankInfoScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  late TabController _tabController;

  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _clabeController = TextEditingController();
  final TextEditingController _swiftController = TextEditingController();

  String _selectedAccountType = 'checking';
  bool _hasInternationalAccount = false;
  String? _psychologistId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.psychologist != null) {
      _psychologistId = authState.psychologist!.uid;

      context.read<BankInfoBloc>().add(LoadBankInfo(_psychologistId!));
      context.read<BankInfoBloc>().add(LoadPaymentHistory(_psychologistId!));
    }
  }

  void _populateFields(BankInfoModel bankInfo) {
    _accountHolderController.text = bankInfo.accountHolderName;
    _bankNameController.text = bankInfo.bankName;
    _accountNumberController.text = bankInfo.accountNumber;
    _clabeController.text = bankInfo.clabe;
    _selectedAccountType = bankInfo.accountType;
    _hasInternationalAccount = bankInfo.isInternational;
    if (bankInfo.swiftCode != null) {
      _swiftController.text = bankInfo.swiftCode!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _clabeController.dispose();
    _swiftController.dispose();
    super.dispose();
  }

  void _saveBankInfo() {
    if (_psychologistId == null) return;

    if (_accountHolderController.text.isEmpty ||
        _bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _clabeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_clabeController.text.length != 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La CLABE debe tener 18 dígitos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bankInfo = BankInfoModel(
      psychologistId: _psychologistId!,
      accountHolderName: _accountHolderController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountType: _selectedAccountType,
      accountNumber: _accountNumberController.text.trim(),
      clabe: _clabeController.text.trim(),
      isInternational: _hasInternationalAccount,
      swiftCode: _hasInternationalAccount ? _swiftController.text.trim() : null,
    );

    final currentState = context.read<BankInfoBloc>().state;
    if (currentState.bankInfo == null) {
      context.read<BankInfoBloc>().add(SaveBankInfo(bankInfo));
    } else {
      context.read<BankInfoBloc>().add(UpdateBankInfo(bankInfo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BankInfoBloc, BankInfoState>(
      listener: (context, state) {
        if (state.status == BankInfoStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error desconocido'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.status == BankInfoStatus.success) {
          if (state.bankInfo != null && _accountHolderController.text.isEmpty) {
            _populateFields(state.bankInfo!);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Información de Pagos',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
          backgroundColor: accentColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Datos Bancarios',
              ),
              Tab(icon: Icon(Icons.history), text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildBankDataTab(), _buildPaymentHistoryTab()],
        ),
        
      ),
    );
  }

  Widget _buildBankDataTab() {
    return BlocBuilder<BankInfoBloc, BankInfoState>(
      builder: (context, state) {
        if (state.status == BankInfoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightAccentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: accentColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ingresa tus datos bancarios para recibir los pagos de tus consultas de forma segura.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'DATOS DE LA CUENTA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.8,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _accountHolderController,
                label: 'Nombre del titular',
                hint: 'Nombre completo como aparece en la cuenta',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _bankNameController,
                label: 'Nombre del banco',
                hint: 'Ej: BBVA, Santander, Banorte',
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 20),
              Text(
                'Tipo de cuenta',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedAccountType = 'checking'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedAccountType == 'checking'
                                ? lightAccentColor
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 18,
                                color: _selectedAccountType == 'checking'
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Corriente',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedAccountType == 'checking'
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedAccountType = 'savings'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedAccountType == 'savings'
                                ? lightAccentColor
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 18,
                                color: _selectedAccountType == 'savings'
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ahorro',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedAccountType == 'savings'
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _accountNumberController,
                label: 'Número de cuenta',
                hint: 'Ingresa tu número de cuenta',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _clabeController,
                label: 'CLABE Interbancaria',
                hint: '18 dígitos',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                maxLength: 18,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: accentColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuenta internacional',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'Activa si tu cuenta es de otro país',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hasInternationalAccount,
                      onChanged: (value) =>
                          setState(() => _hasInternationalAccount = value),
                      activeColor: lightAccentColor,
                    ),
                  ],
                ),
              ),
              if (_hasInternationalAccount) ...[
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _swiftController,
                  label: 'Código SWIFT/BIC',
                  hint: 'Ej: BMSXMXMM',
                  icon: Icons.code,
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.status == BankInfoStatus.loading
                      ? null
                      : _saveBankInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: state.status == BankInfoStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Información Bancaria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tus datos bancarios están protegidos con encriptación de alto nivel',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Reemplaza el método _buildPaymentHistoryTab en bank_info_screen.dart

  Widget _buildPaymentHistoryTab() {
    return BlocBuilder<BankInfoBloc, BankInfoState>(
      builder: (context, state) {
        if (state.status == BankInfoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Ganado',
                      amount:
                          '\$${state.totalEarned.toStringAsFixed(2)}', // ✅ Interpolación correcta
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Pendiente',
                      amount:
                          '\$${state.pendingAmount.toStringAsFixed(2)}', // ✅ Interpolación correcta
                      icon: Icons.pending_outlined,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HISTORIAL DE PAGOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.8,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: accentColor),
                    onPressed: () => _showFilterDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.filteredPayments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay pagos registrados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los pagos aparecerán aquí cuando se procesen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.filteredPayments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(state.filteredPayments[index]);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Reemplaza el método _buildSummaryCard en bank_info_screen.dart

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
  final bool isCompleted = payment.status == 'completed';
  final Color statusColor = isCompleted ? Colors.green : Colors.orange;

  return InkWell(
    onTap: () => _showPaymentDetailsDialog(context, payment),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.patientName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event_note, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${payment.sessions} sesión${payment.sessions > 1 ? 'es' : ''}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDate(payment.date),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted ? 'Pagado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
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

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentDetailsDialog(BuildContext context, PaymentModel payment) {
  final bool isCompleted = payment.status == 'completed';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Detalles del Pago',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Psicólogo:', payment.psychologistName),
              _buildDetailRow('Email:', payment.psychologistEmail),
              const Divider(height: 24),
              _buildDetailRow('Fecha de pago:', _formatDate(payment.paidAt)),
              _buildDetailRow('Fecha de registro:', _formatDate(payment.registeredAt)),
              _buildDetailRow('Sesiones:', '${payment.sessions}'),
              const Divider(height: 24),
              _buildDetailRow('Monto:', '\$${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Monto calculado:', '\$${payment.calculatedAmount.toStringAsFixed(2)}'),
              _buildDetailRowFlexible('Método de pago:', _getPaymentMethodName(payment.paymentMethod)),  // ✅ Cambiado
              _buildDetailRow('Referencia:', payment.reference),
              _buildDetailRow('Estado:', isCompleted ? 'Completado' : 'Pendiente'),
              
              if (payment.bankInfo != null) ...[
                const Divider(height: 24),
                Text(
                  'Información Bancaria',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Titular:', payment.bankInfo!.accountHolder),
                _buildDetailRow('Banco:', payment.bankInfo!.bankName),
                _buildDetailRow('CLABE:', payment.bankInfo!.clabe),
              ],

              if (payment.notes.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Notas:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.notes,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.info_outline,
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCompleted
                            ? 'El pago fue transferido a tu cuenta'
                            : 'El pago se procesará en 2-3 días hábiles',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (payment.receipt != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showReceiptDialog(context, payment.receipt!),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Ver comprobante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightAccentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: TextStyle(color: accentColor, fontFamily: 'Poppins')),
          ),
        ],
      );
    },
  );
}

// ✅ Nuevo método para filas con texto flexible
Widget _buildDetailRowFlexible(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 14, 
            color: Colors.grey[600], 
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value, 
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600, 
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}
Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins')),
        Flexible(
          child: Text(
            value, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Transferencia bancaria';
      case 'card':
        return 'Tarjeta';
      case 'cash':
        return 'Efectivo';
      default:
        return method;
    }
  }

 void _showReceiptDialog(BuildContext context, ReceiptData receipt) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Comprobante de Pago',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (receipt.base64.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(receipt.base64.split(',').last),
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildReceiptDetailRow('Archivo:', receipt.fileName),
              _buildReceiptDetailRow('Tamaño:', '${(receipt.fileSize / 1024).toStringAsFixed(2)} KB'),
              _buildReceiptDetailRow('Tipo:', receipt.fileType),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: TextStyle(color: accentColor, fontFamily: 'Poppins')),
          ),
        ],
      );
    },
  );
}

// ✅ Nuevo método específico para el diálogo de comprobante
Widget _buildReceiptDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
 

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Filtrar Pagos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text(
                  'Todos',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  context.read<BankInfoBloc>().add(const FilterPayments('all'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green[600]),
                title: const Text(
                  'Completados',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  context.read<BankInfoBloc>().add(
                    const FilterPayments('completed'),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.pending, color: Colors.orange[600]),
                title: const Text(
                  'Pendientes',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  context.read<BankInfoBloc>().add(
                    const FilterPayments('pending'),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Ayuda - Información de Pagos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'DATOS BANCARIOS:\n'
              'Aquí puedes registrar tus datos bancarios para recibir los pagos de tus consultas.\n\n'
              '• Titular: Nombre completo del dueño de la cuenta\n'
              '• CLABE: Número de 18 dígitos para transferencias\n'
              '• Cuenta internacional: Activa si tu banco está fuera de México\n'
              '• SWIFT/BIC: Código internacional del banco\n\n'
              'HISTORIAL:\n'
              'Visualiza todos los pagos recibidos y pendientes.\n\n'
              '• Pagos completados: Transferidos a tu cuenta\n'
              '• Pagos pendientes: Se procesarán en 2-3 días hábiles\n\n'
              'Tus datos están protegidos y encriptados.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
