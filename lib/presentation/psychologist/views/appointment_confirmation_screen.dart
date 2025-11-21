/// lib/presentation/psychologist/views


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';

class AppointmentConfirmationScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentConfirmationScreen({super.key, required this.appointment});

  @override
  State<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends State<AppointmentConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _meetingLinkController = TextEditingController();
  
  bool _dialogShown = false;

  @override
  void dispose() {
    try {
      _notesController.dispose();
    } catch (e) {
      // Error disposing notes controller
    }

    try {
      _meetingLinkController.dispose();
    } catch (e) {
      // Error disposing meeting link controller
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listenWhen: (previous, current) {
        return !_dialogShown && (
          (previous.status != current.status) &&
          (current.isConfirmed || 
           current.isSessionStarted || 
           current.isSessionCompleted || 
           current.isCancelled ||
           current.isError)
        );
      },
      listener: (context, state) {
        if (!mounted || _dialogShown) return;
        _dialogShown = true;

        if (state.isConfirmed) {
          _showSuccessDialog(
            title: 'Cita Confirmada',
            message: state.message ?? 'La cita ha sido confirmada exitosamente.',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          );
        } else if (state.isSessionStarted) {
          _showSuccessDialog(
            title: 'Sesión Iniciada',
            message: state.message ?? 'La sesión ha sido iniciada correctamente.',
            icon: Icons.play_circle_outline,
            color: Colors.blue,
          );
        } else if (state.isSessionCompleted) {
          _showSuccessDialog(
            title: 'Sesión Completada',
            message: state.message ?? 'La sesión ha sido completada exitosamente.',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          );
        } else if (state.isCancelled) {
          _showSuccessDialog(
            title: 'Cita Cancelada',
            message: state.message ?? 'La cita ha sido cancelada exitosamente.',
            icon: Icons.cancel_outlined,
            color: Colors.orange,
          );
        } else if (state.isError) {
          _showErrorDialog(state.errorMessage ?? 'Ocurrió un error inesperado.');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: ResponsiveUtils.getIconSize(context, 24),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: ResponsiveText(
        'Confirmar Cita',
        baseFontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: ResponsiveContainer(
              padding: ResponsiveUtils.getContentMargin(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
                  ResponsiveSpacing(24),
                  _buildPatientInfo(),
                  ResponsiveSpacing(24),
                  _buildAppointmentDetails(),
                  ResponsiveSpacing(24),
                  if (widget.appointment.patientNotes != null) ...[
                    _buildPatientNotes(),
                    ResponsiveSpacing(24),
                  ],
                  if (widget.appointment.isPending) ...[
                    _buildConfirmationForm(),
                    ResponsiveSpacing(24),
                  ],
                  _buildActionButtons(),
                  ResponsiveSpacing(24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    if (!mounted) return;

    final dialogWidth = ResponsiveUtils.getDialogWidth(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: ResponsiveUtils.getIconSize(context, 80),
                  height: ResponsiveUtils.getIconSize(context, 80),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveUtils.getIconSize(context, 50),
                  ),
                ),
                ResponsiveSpacing(24),
                ResponsiveText(
                  title,
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(12),
                ResponsiveText(
                  message,
                  baseFontSize: 14,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                ResponsiveSpacing(24),
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveUtils.getButtonHeight(context),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                    child: ResponsiveText(
                      'OK',
                      baseFontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _dialogShown = false;
        });
      }
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    final dialogWidth = ResponsiveUtils.getDialogWidth(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, 16),
          ),
        ),
        child: Container(
          width: dialogWidth,
          padding: ResponsiveUtils.getCardPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveUtils.getIconSize(context, 80),
                height: ResponsiveUtils.getIconSize(context, 80),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: ResponsiveUtils.getIconSize(context, 50),
                ),
              ),
              ResponsiveSpacing(24),
              ResponsiveText(
                'Error',
                baseFontSize: 20,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(12),
              ResponsiveText(
                message,
                baseFontSize: 14,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveSpacing(24),
              SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.getButtonHeight(context),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 12),
                      ),
                    ),
                  ),
                  child: ResponsiveText(
                    'OK',
                    baseFontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _dialogShown = false;
        });
      }
    });
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (widget.appointment.status) {
      case AppointmentStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.schedule;
        text = 'Pendiente de confirmación';
        break;
      case AppointmentStatus.confirmed:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        text = 'Confirmada';
        break;
      case AppointmentStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        text = 'Cancelada';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.info;
        text = widget.appointment.status.displayName;
    }

    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getCardPadding(context),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: ResponsiveUtils.getIconSize(context, 24),
          ),
          ResponsiveHorizontalSpacing(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Estado de la cita',
                  baseFontSize: 12,
                  color: textColor.withOpacity(0.8),
                ),
                ResponsiveSpacing(2),
                ResponsiveText(
                  text,
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 // lib/presentation/psychologist/views/appointment_confirmation_screen.dart
// Versión completa mejorada

  Widget _buildPatientInfo() {
    return Container(
      padding: ResponsiveUtils.getCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  'Información del Paciente',
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(16),
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.getAvatarRadius(
                  context,
                  ResponsiveUtils.isMobileSmall(context) ? 24 : 30,
                ),
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                backgroundImage: widget.appointment.patientProfileUrl != null
                    ? NetworkImage(widget.appointment.patientProfileUrl!)
                    : null,
                child: widget.appointment.patientProfileUrl == null
                    ? ResponsiveText(
                        widget.appointment.patientName.isNotEmpty
                            ? widget.appointment.patientName[0].toUpperCase()
                            : '?',
                        baseFontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.lightAccentColor,
                      )
                    : null,
              ),
              ResponsiveHorizontalSpacing(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      widget.appointment.patientName,
                      baseFontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveSpacing(4),
                    ResponsiveText(
                      widget.appointment.patientEmail,
                      baseFontSize: 14,
                      color: Colors.grey[600],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveSpacing(8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getHorizontalSpacing(context, 8),
                        vertical: ResponsiveUtils.getVerticalSpacing(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 12),
                        ),
                      ),
                      child: ResponsiveText(
                        'Nuevo Paciente',
                        baseFontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.lightAccentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: ResponsiveUtils.getCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  'Detalles de la Cita',
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(16),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: widget.appointment.formattedDate,
          ),
          ResponsiveSpacing(12),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Hora',
            value: widget.appointment.timeRange,
          ),
          ResponsiveSpacing(12),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Duración',
            value: widget.appointment.formattedDuration,
          ),
          ResponsiveSpacing(12),
          _buildDetailRow(
            icon: widget.appointment.type == AppointmentType.online
                ? Icons.videocam
                : Icons.location_on,
            label: 'Modalidad',
            value: widget.appointment.type.displayName,
          ),
          ResponsiveSpacing(12),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Precio',
            value: '\$${widget.appointment.price.toInt()}',
          ),
          if (widget.appointment.isToday) ...[
            ResponsiveSpacing(16),
            Container(
              padding: ResponsiveUtils.getCardPadding(context).copyWith(
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: AppConstants.lightAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
                border: Border.all(
                  color: AppConstants.lightAccentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.today,
                    color: AppConstants.lightAccentColor,
                    size: ResponsiveUtils.getIconSize(context, 16),
                  ),
                  ResponsiveHorizontalSpacing(8),
                  Expanded(
                    child: ResponsiveText(
                      '¡Esta cita es HOY!',
                      baseFontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.lightAccentColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.appointment.isTomorrow) ...[
            ResponsiveSpacing(16),
            Container(
              padding: ResponsiveUtils.getCardPadding(context).copyWith(
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.orange,
                    size: ResponsiveUtils.getIconSize(context, 16),
                  ),
                  ResponsiveHorizontalSpacing(8),
                  Expanded(
                    child: ResponsiveText(
                      'Esta cita es mañana',
                      baseFontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.getIconSize(context, 18),
          color: Colors.grey[600],
        ),
        ResponsiveHorizontalSpacing(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                label,
                baseFontSize: 12,
                color: Colors.grey[600],
              ),
              ResponsiveSpacing(2),
              ResponsiveText(
                value,
                baseFontSize: 14,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientNotes() {
    return Container(
      padding: ResponsiveUtils.getCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  'Notas del Paciente',
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(12),
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getCardPadding(context),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, 8),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ResponsiveText(
              widget.appointment.patientNotes!,
              baseFontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      padding: ResponsiveUtils.getCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  'Confirmar Cita',
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(16),
          ResponsiveText(
            'Notas profesionales (opcional)',
            baseFontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          ResponsiveSpacing(8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: ResponsiveUtils.getFontSize(context, 14),
            ),
            decoration: InputDecoration(
              hintText:
                  'Agregar notas sobre la preparación de la sesión, recordatorios o instrucciones...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: AppConstants.lightAccentColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: ResponsiveUtils.getCardPadding(context),
            ),
          ),
          if (widget.appointment.type == AppointmentType.online) ...[
            ResponsiveSpacing(16),
            ResponsiveText(
              'Enlace de videollamada',
              baseFontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            ResponsiveSpacing(8),
            TextField(
              controller: _meetingLinkController,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              decoration: InputDecoration(
                hintText: 'https://meet.google.com/...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                ),
                prefixIcon: Icon(
                  Icons.videocam,
                  color: AppConstants.lightAccentColor,
                  size: ResponsiveUtils.getIconSize(context, 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: AppConstants.lightAccentColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: ResponsiveUtils.getCardPadding(context),
              ),
            ),
            ResponsiveSpacing(8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveUtils.getIconSize(context, 16),
                  color: Colors.grey[600],
                ),
                ResponsiveHorizontalSpacing(8),
                Expanded(
                  child: ResponsiveText(
                    'Proporciona el enlace para la videollamada. El paciente lo recibirá por email.',
                    baseFontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!widget.appointment.isPending) {
      return Column(
        children: [
          if (widget.appointment.isConfirmed) ...[
            ResponsiveSpacing(12),
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getButtonHeight(context),
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    onPressed: state.isLoading ? null : _startSession,
                    icon: state.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: ResponsiveUtils.getIconSize(context, 20),
                          ),
                    label: ResponsiveText(
                      state.isLoading ? 'Iniciando...' : 'Iniciar Sesión',
                      baseFontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getVerticalSpacing(context, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ResponsiveSpacing(12),
          ],
          if (widget.appointment.status == AppointmentStatus.in_progress) ...[
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getButtonHeight(context),
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    onPressed: state.isLoading ? null : _completeSession,
                    icon: state.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            color: Colors.white,
                            size: ResponsiveUtils.getIconSize(context, 20),
                          ),
                    label: ResponsiveText(
                      state.isLoading ? 'Completando...' : 'Completar Sesión',
                      baseFontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getVerticalSpacing(context, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ResponsiveSpacing(12),
          ],
          if (widget.appointment.status != AppointmentStatus.completed &&
              widget.appointment.status != AppointmentStatus.cancelled)
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getButtonHeight(context),
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmationDialog(),
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: ResponsiveUtils.getIconSize(context, 20),
                ),
                label: ResponsiveText(
                  'Cancelar Cita',
                  baseFontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getVerticalSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, 12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Botones para citas pendientes
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getButtonHeight(context),
              child: ElevatedButton.icon(
                onPressed: state.isLoading ? null : _confirmAppointment,
                icon: state.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.check,
                        color: Colors.white,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                label: ResponsiveText(
                  state.isLoading ? 'Confirmando...' : 'Confirmar Cita',
                  baseFontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.lightAccentColor,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getVerticalSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, 12),
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(12),
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getButtonHeight(context),
              child: OutlinedButton.icon(
                onPressed: state.isLoading ? null : _showCancelConfirmationDialog,
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: ResponsiveUtils.getIconSize(context, 20),
                ),
                label: ResponsiveText(
                  'Rechazar Cita',
                  baseFontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getVerticalSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmAppointment() {
    if (widget.appointment.type == AppointmentType.online &&
        _meetingLinkController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor proporciona un enlace de videollamada');
      return;
    }

    BlocProvider.of<AppointmentBloc>(context, listen: false).add(
      ConfirmAppointmentEvent(
        appointmentId: widget.appointment.id,
        psychologistNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        meetingLink: widget.appointment.type == AppointmentType.online
            ? _meetingLinkController.text.trim()
            : null,
      ),
    );
  }

  void _showCancelConfirmationDialog() {
    final reasonController = TextEditingController();
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 20),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Cancelar Cita',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  '¿Estás seguro de que deseas cancelar esta cita?',
                  baseFontSize: 14,
                  color: Colors.grey[700],
                ),
                ResponsiveSpacing(16),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Motivo de cancelación',
                    hintText: 'Explica brevemente el motivo...',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ResponsiveUtils.getFontSize(context, 14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 8),
                      ),
                    ),
                    contentPadding: ResponsiveUtils.getCardPadding(context),
                  ),
                ),
                ResponsiveSpacing(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: ResponsiveText(
                        'Volver',
                        baseFontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    ElevatedButton(
                      onPressed: () {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor proporciona un motivo'),
                            ),
                          );
                          return;
                        }
                        Navigator.of(dialogContext).pop(reason);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 8),
                          ),
                        ),
                      ),
                      child: ResponsiveText(
                        'Cancelar Cita',
                        baseFontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((reason) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (reasonController.hasListeners) {
          reasonController.dispose();
        }
      });

      if (reason != null && reason.isNotEmpty && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            BlocProvider.of<AppointmentBloc>(context, listen: false).add(
              CancelAppointmentEvent(
                appointmentId: widget.appointment.id,
                reason: reason,
                isPsychologistCancelling: true,
              ),
            );
          }
        });
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  message,
                  baseFontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 10),
            ),
          ),
        ),
      );
    } catch (e) {
      // Error showing snackbar
    }
  }

  void _completeSession() {
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        final notesController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  'Completar Sesión',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  '¿Estás seguro de que deseas completar esta sesión?',
                  baseFontSize: 14,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Notas de la sesión (opcional)',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ResponsiveUtils.getFontSize(context, 14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 8),
                      ),
                    ),
                    contentPadding: ResponsiveUtils.getCardPadding(context),
                  ),
                ),
                ResponsiveSpacing(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ResponsiveText(
                        'Cancelar',
                        baseFontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    ElevatedButton(
                      onPressed: () {
                        final notes = notesController.text.trim();
                        Navigator.pop(dialogContext);

                        BlocProvider.of<AppointmentBloc>(context).add(
                          CompleteAppointmentSessionEvent(
                            appointmentId: widget.appointment.id,
                            notes: notes.isNotEmpty ? notes : null,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 8),
                          ),
                        ),
                      ),
                      child: ResponsiveText(
                        'Completar',
                        baseFontSize: 14,
                        color: Colors.white,
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

  void _startSession() {
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  'Iniciar Sesión',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  '¿Estás seguro de que deseas iniciar esta sesión?',
                  baseFontSize: 14,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ResponsiveText(
                        'Cancelar',
                        baseFontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        BlocProvider.of<AppointmentBloc>(context).add(
                          StartAppointmentSessionEvent(
                            appointmentId: widget.appointment.id,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 8),
                          ),
                        ),
                      ),
                      child: ResponsiveText(
                        'Iniciar',
                        baseFontSize: 14,
                        color: Colors.white,
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
}