// lib/presentation/psychologist/views/appointment_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
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
  AppointmentStateStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _previousStatus = BlocProvider.of<AppointmentBloc>(context).state.status;
  }

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

  void _closeAnyOpenDialogs() {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error al cerrar diálogo
    }
  }

@override
Widget build(BuildContext context) {
  return BlocListener<AppointmentBloc, AppointmentState>(
    listenWhen: (previous, current) {
      return (previous.isConfirmed != current.isConfirmed) ||
          (previous.isSessionStarted != current.isSessionStarted) ||
          (previous.isSessionCompleted != current.isSessionCompleted) ||
          (previous.isError != current.isError);
    },
    listener: (context, state) {
      if (!mounted) return;

      if (state.isConfirmed) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de confirmación
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cita Confirmada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message ?? 'La cita ha sido confirmada exitosamente.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (state.isSessionStarted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de sesión iniciada
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.blue,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sesión Iniciada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message ?? 'La sesión ha sido iniciada correctamente.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (state.isSessionCompleted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de sesión completada
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sesión Completada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message ?? 'La sesión ha sido completada exitosamente.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (state.isError) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de error
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Ocurrió un error inesperado.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirmar Cita',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de la cita
              _buildStatusBanner(),
              const SizedBox(height: 24),
              // Información del paciente
              _buildPatientInfo(),
              const SizedBox(height: 24),
              // Detalles de la cita
              _buildAppointmentDetails(),
              const SizedBox(height: 24),
              // Notes del paciente 
              if (widget.appointment.patientNotes != null) ...[
                _buildPatientNotes(),
                const SizedBox(height: 24),
              ],
              // Formulario de confirmación
              if (widget.appointment.isPending) ...[
                _buildConfirmationForm(),
                const SizedBox(height: 24),
              ],
              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    ),
  );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de la cita',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.person, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Información del Paciente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                backgroundImage: widget.appointment.patientProfileUrl != null
                    ? NetworkImage(widget.appointment.patientProfileUrl!)
                    : null,
                child: widget.appointment.patientProfileUrl == null
                    ? Text(
                        widget.appointment.patientName.isNotEmpty
                            ? widget.appointment.patientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppConstants.lightAccentColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.appointment.patientEmail,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.lightAccentColor.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Nuevo Paciente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.lightAccentColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.event, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Detalles de la Cita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: widget.appointment.formattedDate,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Hora',
            value: widget.appointment.timeRange,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Duración',
            value: widget.appointment.formattedDuration,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: widget.appointment.type == AppointmentType.online
                ? Icons.videocam
                : Icons.location_on,
            label: 'Modalidad',
            value: widget.appointment.type.displayName,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Precio',
            value: '\$${widget.appointment.price.toInt()}',
          ),
          if (widget.appointment.isToday) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.lightAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.lightAccentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.today,
                    color: AppConstants.lightAccentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¡Esta cita es HOY!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.lightAccentColor,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.appointment.isTomorrow) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Esta cita es mañana',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                      fontFamily: 'Poppins',
                      fontSize: 14,
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
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.note, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notas del Paciente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.appointment.patientNotes!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.edit_note, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Confirmar Cita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Notas profesionales
          Text(
            'Notas profesionales (opcional)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Agregar notas sobre la preparación de la sesión, recordatorios o instrucciones...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppConstants.lightAccentColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
          if (widget.appointment.type == AppointmentType.online) ...[
            const SizedBox(height: 16),
            // Enlace de reunión
            Text(
              'Enlace de videollamada',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _meetingLinkController,
              decoration: InputDecoration(
                hintText: 'https://meet.google.com/...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.videocam,
                  color: AppConstants.lightAccentColor,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppConstants.lightAccentColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proporciona el enlace para la videollamada. El paciente lo recibirá por email.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar inicio de videollamada o navegación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de iniciar sesión próximamente'),
                  ),
                );
              },
              icon: Icon(
                widget.appointment.type == AppointmentType.online
                    ? Icons.videocam
                    : Icons.location_on,
                color: Colors.white,
              ),
              label: Text(
                widget.appointment.type == AppointmentType.online
                    ? 'Iniciar Videollamada'
                    : 'Ver Ubicación',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.lightAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                return ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _startSession,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(
                    state.isLoading ? 'Iniciando...' : 'Iniciar Sesión',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
       
        if (widget.appointment.status == AppointmentStatus.in_progress) ...[
          SizedBox(
            width: double.infinity,
            child: BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                return ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _completeSession,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    state.isLoading ? 'Completando...' : 'Completar Sesión',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Muestra el botón de cancelar solo si la cita no está completada o cancelada
        if (widget.appointment.status != AppointmentStatus.completed &&
            widget.appointment.status != AppointmentStatus.cancelled)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelConfirmationDialog(),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text(
                'Cancelar Cita',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
          // Botón de confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : _confirmAppointment,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                state.isLoading ? 'Confirmando...' : 'Confirmar Cita',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.lightAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón de cancelar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isLoading ? null : _showCancelConfirmationDialog,
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text(
                'Rechazar Cita',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    // Validar enlace de reunión para citas online
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

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cancelar Cita',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas cancelar esta cita?',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Motivo de cancelación',
                  hintText: 'Explica brevemente el motivo...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Volver'),
            ),
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
              ),
              child: Text('Cancelar Cita'),
            ),
          ],
        );
      },
    ).then((reason) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (reasonController.hasListeners) {
          reasonController.dispose();
        }
      });

      if (reason != null && reason.isNotEmpty && mounted) {
        // Pequeño delay para asegurar que el dispose se complete
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

void _showSuccessDialog() {
  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Palomita de confirmación
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Cita confirmada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'La cita ha sido confirmada exitosamente. El paciente será notificado.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(true);
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}



void _showCancelDialog() {
  final reasonController = TextEditingController();

  showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cancelar Cita',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '¿Estás seguro de que deseas cancelar esta cita?',
              style: TextStyle(
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo de cancelación',
                hintText: 'Explica brevemente el motivo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Volver',
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
          ),
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
            ),
            child: const Text('Cancelar Cita'),
          ),
        ],
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
          content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Error showing snackbar
    }
  }

  void _completeSession() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final notesController = TextEditingController();

        return AlertDialog(
          title: const Text('Completar Sesión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Estás seguro de que deseas completar esta sesión?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas de la sesión (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
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
              child: const Text('Completar'),
            ),
          ],
        );
      },
    );
  }

  void _startSession() {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Iniciar Sesión'),
        content: const Text('¿Estás seguro de que deseas iniciar esta sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              BlocProvider.of<AppointmentBloc>(context).add(
                StartAppointmentSessionEvent(
                  appointmentId: widget.appointment.id,
                ),
              );
            },
            child: const Text('Iniciar'),
          ),
        ],
      );
    },
  );
}
}
