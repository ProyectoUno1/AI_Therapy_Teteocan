// lib/presentation/psychologist/views/appointment_confirmation_screen.dart
// Versión corregida con responsividad mejorada

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  bool _dialogShown = false;

  // SISTEMA MEJORADO DE RESPONSIVIDAD
  double _getResponsiveFontSize(double baseSize, BuildContext context) {
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 350) {
      return baseSize * 0.75; // Teléfonos muy pequeños
    } else if (shortestSide < 400) {
      return baseSize * 0.85; // Teléfonos pequeños
    } else if (shortestSide < 600) {
      return baseSize; // Teléfonos normales
    } else if (shortestSide < 900) {
      return baseSize * 1.2; // Tabletas
    } else {
      return baseSize * 1.4; // Tabletas grandes/desktop
    }
  }

  double _getResponsiveIconSize(double baseSize, BuildContext context) {
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 350) {
      return baseSize * 0.7;
    } else if (shortestSide < 400) {
      return baseSize * 0.8;
    } else if (shortestSide < 600) {
      return baseSize;
    } else if (shortestSide < 900) {
      return baseSize * 1.3;
    } else {
      return baseSize * 1.6;
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < 350) {
      return const EdgeInsets.all(8.0);
    } else if (width < 600) {
      return const EdgeInsets.all(12.0);
    } else if (width < 900) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }

  EdgeInsets _getResponsiveButtonPadding(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < 350) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    } else if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
    }
  }

  double _getResponsiveSpacing(double baseSpacing, BuildContext context) {
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 350) {
      return baseSpacing * 0.6;
    } else if (shortestSide < 400) {
      return baseSpacing * 0.8;
    } else if (shortestSide > 600 && shortestSide < 900) {
      return baseSpacing * 1.2;
    } else if (shortestSide >= 900) {
      return baseSpacing * 1.4;
    }

    return baseSpacing;
  }

  double _getResponsiveButtonHeight(BuildContext context) {
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 350) {
      return 42.0;
    } else if (shortestSide < 400) {
      return 44.0;
    } else if (shortestSide < 600) {
      return 48.0;
    } else {
      return 52.0;
    }
  }

  double _getDialogWidth(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < 350) {
      return width * 0.9;
    } else if (width < 600) {
      return width * 0.85;
    } else if (width < 900) {
      return 500;
    } else {
      return 600;
    }
  }

  double _getMaxDialogHeight(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return height * 0.8; // Máximo 80% de la altura de la pantalla
  }

  double _getBorderRadius(BuildContext context, double baseRadius) {
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide < 350) {
      return baseRadius * 0.8;
    } else if (shortestSide > 900) {
      return baseRadius * 1.2;
    }

    return baseRadius;
  }

  // Nuevo método para calcular el ancho máximo del contenido
  double _getMaxContentWidth(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width > 600 ? 600 : width;
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listenWhen: (previous, current) {
        return !_dialogShown &&
            ((previous.status != current.status) &&
                (current.isConfirmed ||
                    current.isSessionStarted ||
                    current.isSessionCompleted ||
                    current.isCancelled ||
                    current.isError));
      },
      listener: (context, state) {
        if (!mounted || _dialogShown) return;
        _dialogShown = true;

        if (state.isConfirmed) {
          _showSuccessDialog(
            title: 'Cita Confirmada',
            message:
                state.message ?? 'La cita ha sido confirmada exitosamente.',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          );
        } else if (state.isSessionStarted) {
          _showSuccessDialog(
            title: 'Sesión Iniciada',
            message:
                state.message ?? 'La sesión ha sido iniciada correctamente.',
            icon: Icons.play_circle_outline,
            color: Colors.blue,
          );
        } else if (state.isSessionCompleted) {
          _showSuccessDialog(
            title: 'Sesión Completada',
            message:
                state.message ?? 'La sesión ha sido completada exitosamente.',
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
          _showErrorDialog(
            state.errorMessage ?? 'Ocurrió un error inesperado.',
          );
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
          size: _getResponsiveIconSize(24, context),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detalles de cita',
        style: TextStyle(
          fontSize: _getResponsiveFontSize(18, context),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontFamily: 'Poppins',
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _getMaxContentWidth(context);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: _getResponsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(),
                      SizedBox(height: _getResponsiveSpacing(20, context)),
                      _buildPatientInfo(),
                      SizedBox(height: _getResponsiveSpacing(20, context)),
                      _buildAppointmentDetails(),
                      SizedBox(height: _getResponsiveSpacing(20, context)),
                      if (widget.appointment.patientNotes != null) ...[
                        _buildPatientNotes(),
                        SizedBox(height: _getResponsiveSpacing(20, context)),
                      ],
                      if (widget.appointment.isPending) ...[
                        _buildConfirmationForm(),
                        SizedBox(height: _getResponsiveSpacing(20, context)),
                      ],
                      _buildActionButtons(),
                      SizedBox(height: _getResponsiveSpacing(20, context)),
                    ],
                  ),
                ),
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

    final dialogWidth = _getDialogWidth(context);
    final maxDialogHeight = _getMaxDialogHeight(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(context, 16)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: _getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _getResponsiveIconSize(70, context),
                      height: _getResponsiveIconSize(70, context),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: _getResponsiveIconSize(40, context),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(16, context)),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(18, context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getResponsiveSpacing(8, context)),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(14, context),
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getResponsiveSpacing(20, context)),
                    SizedBox(
                      width: double.infinity,
                      height: _getResponsiveButtonHeight(context),
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
                              _getBorderRadius(context, 12),
                            ),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(16, context),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

    final dialogWidth = _getDialogWidth(context);
    final maxDialogHeight = _getMaxDialogHeight(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(context, 16)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: _getResponsivePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _getResponsiveIconSize(70, context),
                    height: _getResponsiveIconSize(70, context),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: _getResponsiveIconSize(40, context),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSpacing(16, context)),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(18, context),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _getResponsiveSpacing(8, context)),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(14, context),
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _getResponsiveSpacing(20, context)),
                  SizedBox(
                    width: double.infinity,
                    height: _getResponsiveButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(context, 12),
                          ),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(16, context),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
      padding: EdgeInsets.all(_getResponsiveSpacing(12, context)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(context, 12)),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: _getResponsiveIconSize(20, context),
          ),
          SizedBox(width: _getResponsiveSpacing(8, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de la cita',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(11, context),
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(2, context)),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(14, context),
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      width: double.infinity,
      padding: _getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(context, 12)),
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
                size: _getResponsiveIconSize(18, context),
              ),
              SizedBox(width: _getResponsiveSpacing(8, context)),
              Expanded(
                child: Text(
                  'Información del Paciente',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(15, context),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, context)),
          Row(
            children: [
              CircleAvatar(
                radius: _getResponsiveIconSize(20, context),
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                backgroundImage: widget.appointment.patientProfileUrl != null
                    ? NetworkImage(widget.appointment.patientProfileUrl!)
                    : null,
                child: widget.appointment.patientProfileUrl == null
                    ? Text(
                        widget.appointment.patientName.isNotEmpty
                            ? widget.appointment.patientName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(16, context),
                          fontWeight: FontWeight.bold,
                          color: AppConstants.lightAccentColor,
                          fontFamily: 'Poppins',
                        ),
                      )
                    : null,
              ),
              SizedBox(width: _getResponsiveSpacing(12, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment.patientName,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(16, context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _getResponsiveSpacing(4, context)),
                    Text(
                      widget.appointment.patientEmail,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(13, context),
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _getResponsiveSpacing(6, context)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSpacing(6, context),
                        vertical: _getResponsiveSpacing(3, context),
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          _getBorderRadius(context, 8),
                        ),
                      ),
                      child: Text(
                        'Nuevo Paciente',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(11, context),
                          fontWeight: FontWeight.w600,
                          color: AppConstants.lightAccentColor,
                          fontFamily: 'Poppins',
                        ),
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
      width: double.infinity,
      padding: _getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(context, 12)),
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
                size: _getResponsiveIconSize(18, context),
              ),
              SizedBox(width: _getResponsiveSpacing(8, context)),
              Expanded(
                child: Text(
                  'Detalles de la Cita',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(15, context),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, context)),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: widget.appointment.formattedDate,
          ),
          SizedBox(height: _getResponsiveSpacing(10, context)),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Hora',
            value: widget.appointment.timeRange,
          ),
          SizedBox(height: _getResponsiveSpacing(10, context)),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Duración',
            value: widget.appointment.formattedDuration,
          ),
          SizedBox(height: _getResponsiveSpacing(10, context)),
          _buildDetailRow(
            icon: widget.appointment.type == AppointmentType.online
                ? Icons.videocam
                : Icons.location_on,
            label: 'Modalidad',
            value: widget.appointment.type.displayName,
          ),
          SizedBox(height: _getResponsiveSpacing(10, context)),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Precio',
            value: '\$${widget.appointment.price.toInt()}',
          ),
          if (widget.appointment.isToday) ...[
            SizedBox(height: _getResponsiveSpacing(12, context)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSpacing(10, context)),
              decoration: BoxDecoration(
                color: AppConstants.lightAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(context, 8),
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
                    size: _getResponsiveIconSize(16, context),
                  ),
                  SizedBox(width: _getResponsiveSpacing(8, context)),
                  Expanded(
                    child: Text(
                      '¡Esta cita es HOY!',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(13, context),
                        fontWeight: FontWeight.w600,
                        color: AppConstants.lightAccentColor,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.appointment.isTomorrow) ...[
            SizedBox(height: _getResponsiveSpacing(12, context)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSpacing(10, context)),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(context, 8),
                ),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.orange,
                    size: _getResponsiveIconSize(16, context),
                  ),
                  SizedBox(width: _getResponsiveSpacing(8, context)),
                  Expanded(
                    child: Text(
                      'Esta cita es mañana',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(13, context),
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                        fontFamily: 'Poppins',
                      ),
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
          size: _getResponsiveIconSize(16, context),
          color: Colors.grey[600],
        ),
        SizedBox(width: _getResponsiveSpacing(10, context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(11, context),
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: _getResponsiveSpacing(2, context)),
              Text(
                value,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(13, context),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
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
      width: double.infinity,
      padding: _getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(context, 12)),
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
                size: _getResponsiveIconSize(18, context),
              ),
              SizedBox(width: _getResponsiveSpacing(8, context)),
              Expanded(
                child: Text(
                  'Notas del Paciente',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(15, context),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, context)),
          Container(
            width: double.infinity,
            padding: _getResponsivePadding(context),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(_getBorderRadius(context, 8)),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.appointment.patientNotes!,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(13, context),
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      width: double.infinity,
      padding: _getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_getBorderRadius(context, 12)),
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
                size: _getResponsiveIconSize(18, context),
              ),
              SizedBox(width: _getResponsiveSpacing(8, context)),
              Expanded(
                child: Text(
                  'Confirmar Cita',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(15, context),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, context)),
          Text(
            'Notas profesionales (opcional)',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(13, context),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(6, context)),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: _getResponsiveFontSize(13, context),
            ),
            decoration: InputDecoration(
              hintText:
                  'Agregar notas sobre la preparación de la sesión, recordatorios o instrucciones...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: _getResponsiveFontSize(11, context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(context, 8),
                ),
                borderSide: BorderSide(color: AppConstants.lightAccentColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.all(
                _getResponsiveSpacing(12, context),
              ),
            ),
          ),
          if (widget.appointment.type == AppointmentType.online) ...[
            SizedBox(height: _getResponsiveSpacing(12, context)),
            Text(
              'Enlace de videollamada',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(13, context),
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(6, context)),
            TextField(
              controller: _meetingLinkController,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: _getResponsiveFontSize(13, context),
              ),
              decoration: InputDecoration(
                hintText: 'https://meet.google.com/...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                  fontSize: _getResponsiveFontSize(13, context),
                ),
                prefixIcon: Icon(
                  Icons.videocam,
                  color: AppConstants.lightAccentColor,
                  size: _getResponsiveIconSize(18, context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(context, 8),
                  ),
                  borderSide: BorderSide(color: AppConstants.lightAccentColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.all(
                  _getResponsiveSpacing(12, context),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(6, context)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: _getResponsiveIconSize(14, context),
                  color: Colors.grey[600],
                ),
                SizedBox(width: _getResponsiveSpacing(6, context)),
                Expanded(
                  child: Text(
                    'Proporciona el enlace para la videollamada. El paciente lo recibirá por email.',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(11, context),
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
            SizedBox(height: _getResponsiveSpacing(10, context)),
            SizedBox(
              width: double.infinity,
              height: _getResponsiveButtonHeight(context),
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isLoading ? null : _startSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: _getResponsiveButtonPadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                    child: state.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: _getResponsiveIconSize(18, context),
                                ),
                                SizedBox(
                                  width: _getResponsiveSpacing(6, context),
                                ),
                                Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      14,
                                      context,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(10, context)),
          ],
          if (widget.appointment.status == AppointmentStatus.in_progress) ...[
            SizedBox(
              width: double.infinity,
              height: _getResponsiveButtonHeight(context),
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isLoading ? null : _completeSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: _getResponsiveButtonPadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                    child: state.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: _getResponsiveIconSize(18, context),
                                ),
                                SizedBox(
                                  width: _getResponsiveSpacing(6, context),
                                ),
                                Text(
                                  'Completar Sesión',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      14,
                                      context,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(10, context)),
          ],
          if (widget.appointment.status != AppointmentStatus.completed &&
              widget.appointment.status != AppointmentStatus.cancelled)
            SizedBox(
              width: double.infinity,
              height: _getResponsiveButtonHeight(context),
              child: OutlinedButton(
                onPressed: () => _showCancelConfirmationDialog(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: _getResponsiveButtonPadding(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(context, 12),
                    ),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: _getResponsiveIconSize(18, context),
                      ),
                      SizedBox(width: _getResponsiveSpacing(6, context)),
                      Text(
                        'Cancelar Cita',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(14, context),
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Botones para citas pendientes - MEJORADOS
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: _getResponsiveButtonHeight(context),
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _confirmAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.lightAccentColor,
                  padding: _getResponsiveButtonPadding(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(context, 12),
                    ),
                  ),
                ),
                child: state.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              color: Colors.white,
                              size: _getResponsiveIconSize(18, context),
                            ),
                            SizedBox(width: _getResponsiveSpacing(6, context)),
                            Text(
                              'Confirmar Cita',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(14, context),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(10, context)),
            SizedBox(
              width: double.infinity,
              height: _getResponsiveButtonHeight(context),
              child: OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : _showCancelConfirmationDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: _getResponsiveButtonPadding(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(context, 12),
                    ),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: _getResponsiveIconSize(18, context),
                      ),
                      SizedBox(width: _getResponsiveSpacing(6, context)),
                      Text(
                        'Rechazar Cita',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(14, context),
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
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
    final dialogWidth = _getDialogWidth(context);
    final maxDialogHeight = _getMaxDialogHeight(context);

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(context, 16)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: _getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancelar Cita',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(18, context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(12, context)),
                    Text(
                      '¿Estás seguro de que deseas cancelar esta cita?',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(14, context),
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(12, context)),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: _getResponsiveFontSize(14, context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Motivo de cancelación',
                        hintText: 'Explica brevemente el motivo...',
                        labelStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: _getResponsiveFontSize(14, context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(context, 8),
                          ),
                        ),
                        contentPadding: EdgeInsets.all(
                          _getResponsiveSpacing(12, context),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(20, context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: _getResponsiveButtonPadding(context),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Volver',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSpacing(8, context)),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                              final reason = reasonController.text.trim();
                              if (reason.isEmpty) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Por favor proporciona un motivo',
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(
                                          14,
                                          context,
                                        ),
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              Navigator.of(dialogContext).pop(reason);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: _getResponsiveButtonPadding(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _getBorderRadius(context, 8),
                                ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Cancelar Cita',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                size: _getResponsiveIconSize(18, context),
              ),
              SizedBox(width: _getResponsiveSpacing(6, context)),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(13, context),
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(context, 10)),
          ),
        ),
      );
    } catch (e) {
      // Error showing snackbar
    }
  }

  void _completeSession() {
    final dialogWidth = _getDialogWidth(context);
    final maxDialogHeight = _getMaxDialogHeight(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final notesController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(context, 16)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: _getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Completar Sesión',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(18, context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(12, context)),
                    Text(
                      '¿Estás seguro de que deseas completar esta sesión?',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(14, context),
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getResponsiveSpacing(12, context)),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: _getResponsiveFontSize(14, context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notas de la sesión (opcional)',
                        labelStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: _getResponsiveFontSize(14, context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(context, 8),
                          ),
                        ),
                        contentPadding: EdgeInsets.all(
                          _getResponsiveSpacing(12, context),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(20, context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              padding: _getResponsiveButtonPadding(context),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSpacing(8, context)),
                        Flexible(
                          child: ElevatedButton(
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
                              padding: _getResponsiveButtonPadding(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _getBorderRadius(context, 8),
                                ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Completar',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startSession() {
    final dialogWidth = _getDialogWidth(context);
    final maxDialogHeight = _getMaxDialogHeight(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(context, 16)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: _getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(18, context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(12, context)),
                    Text(
                      '¿Estás seguro de que deseas iniciar esta sesión?',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(14, context),
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getResponsiveSpacing(20, context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              padding: _getResponsiveButtonPadding(context),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSpacing(8, context)),
                        Flexible(
                          child: ElevatedButton(
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
                              padding: _getResponsiveButtonPadding(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _getBorderRadius(context, 8),
                                ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Iniciar',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(14, context),
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
