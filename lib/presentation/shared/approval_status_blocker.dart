// lib/presentation/shared/approval_status_blocker.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';

class ApprovalStatusBlocker extends StatelessWidget {
  final PsychologistModel? psychologist;
  final Widget child;
  final String featureName;

  const ApprovalStatusBlocker({
    super.key,
    required this.psychologist,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    if (psychologist == null || _isApproved()) {
      return child;
    }

    return _buildBlockedContent(context);
  }

  bool _isApproved() {
    return psychologist!.status == 'ACTIVE' || 
           (psychologist!.isApproved ?? false);
  }

  Widget _buildBlockedContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Acceso restringido',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 900;
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width >= 900 ? 700 : (isTablet ? 600 : width),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20.0 : (isTablet ? 32.0 : 40.0),
                  vertical: isMobile ? 16.0 : 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono de estado - Responsivo
                    _buildStatusIcon(isMobile, isTablet, isLandscape),
                    
                    SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
                    
                    // Título
                    _buildTitle(context, isMobile, isTablet),
                    
                    SizedBox(height: isMobile ? 12 : 16),
                    
                    // Descripción
                    _buildDescription(context, isMobile, isTablet),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Estado actual
                    _buildStatusBadge(context, isMobile, isTablet),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Botones de acción
                    _buildActionButtons(context, isMobile, isTablet),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(bool isMobile, bool isTablet, bool isLandscape) {
    final size = isMobile ? 100.0 : (isTablet ? 120.0 : 140.0);
    final iconSize = isMobile ? 50.0 : (isTablet ? 60.0 : 70.0);
    
    return FractionallySizedBox(
      widthFactor: isMobile ? 0.4 : (isTablet ? 0.3 : 0.25),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getStatusIcon(),
              size: iconSize,
              color: _getStatusColor(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool isMobile, bool isTablet) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        _getBlockTitle(),
        style: TextStyle(
          fontSize: isMobile ? 22 : (isTablet ? 26 : 28),
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescription(BuildContext context, bool isMobile, bool isTablet) {
    return Text(
      _getBlockDescription(),
      style: TextStyle(
        fontSize: isMobile ? 15 : (isTablet ? 16 : 17),
        color: Colors.grey[600],
        fontFamily: 'Poppins',
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 500,
      ),
      padding: EdgeInsets.all(isMobile ? 14 : (isTablet ? 16 : 18)),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 8 : 0),
          Flexible(
            child: Text(
              psychologist!.statusDisplayText ?? _getDefaultStatusText(),
              style: TextStyle(
                fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
                fontFamily: 'Poppins',
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile, bool isTablet) {
    if (_isPending() && !psychologist!.professionalInfoCompleted) {
      return _buildPendingButtons(context, isMobile, isTablet);
    } else if (_isRejected()) {
      return _buildRejectedButtons(context, isMobile, isTablet);
    } else {
      return _buildReviewingInfo(context, isMobile, isTablet);
    }
  }

  Widget _buildPendingButtons(BuildContext context, bool isMobile, bool isTablet) {
    return FractionallySizedBox(
      widthFactor: isMobile ? 1.0 : (isTablet ? 0.8 : 0.6),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfessionalInfoSetupScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 14 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: FittedBox(
          child: Text(
            'Completar Perfil Profesional',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedButtons(BuildContext context, bool isMobile, bool isTablet) {
    return Column(
      children: [
        if (psychologist!.rejectionReason != null) ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            margin: EdgeInsets.only(bottom: isMobile ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo del rechazo:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  psychologist!.rejectionReason!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
        FractionallySizedBox(
          widthFactor: isMobile ? 1.0 : (isTablet ? 0.8 : 0.6),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfessionalInfoSetupScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 14 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: FittedBox(
              child: Text(
                'Corregir y Reenviar',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewingInfo(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.blue.shade600,
            size: isMobile ? 18 : 20,
          ),
          SizedBox(width: isMobile ? 0 : 8, height: isMobile ? 8 : 0),
          Flexible(
            child: Text(
              'Tu perfil está siendo revisado...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isMobile ? 13 : 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares (sin cambios)
  bool _isPending() => psychologist!.status == 'PENDING';
  bool _isRejected() => psychologist!.status == 'REJECTED';

  Color _getStatusColor() {
    switch (psychologist!.status) {
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      case 'ACTIVE': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted 
            ? Icons.hourglass_empty 
            : Icons.edit_note;
      case 'REJECTED': return Icons.cancel;
      case 'ACTIVE': return Icons.check_circle;
      default: return Icons.lock;
    }
  }

  String _getStatusText() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted ? 'EN REVISIÓN' : 'PENDIENTE';
      case 'REJECTED': return 'RECHAZADO';
      case 'ACTIVE': return 'ACTIVO';
      default: return 'BLOQUEADO';
    }
  }

  String _getDefaultStatusText() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted 
            ? 'Perfil en revisión' 
            : 'Perfil incompleto';
      case 'REJECTED': return 'Perfil rechazado';
      case 'ACTIVE': return 'Perfil aprobado';
      default: return 'Estado desconocido';
    }
  }

  String _getBlockTitle() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? 'Tu perfil está en revisión'
            : 'Completa tu perfil profesional';
      case 'REJECTED': return 'Tu perfil fue rechazado';
      default: return 'Acceso restringido';
    }
  }

  String _getBlockDescription() {
    final feature = _getFeatureDisplayName();
    
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? 'Tu perfil profesional está siendo revisado por nuestro equipo. Una vez aprobado, podrás acceder a $feature y comenzar a atender pacientes.'
            : 'Para acceder a $feature, primero debes completar tu información profesional. Esto nos ayuda a verificar tu identidad y credenciales.';
      case 'REJECTED':
        return 'Tu perfil profesional no cumplió con nuestros requisitos. Revisa los comentarios, corrige la información y reenvía tu solicitud para acceder a $feature.';
      default:
        return 'No puedes acceder a $feature hasta que tu perfil profesional sea aprobado.';
    }
  }

  String _getFeatureDisplayName() {
    switch (featureName.toLowerCase()) {
      case 'chats': return 'los chats con pacientes';
      case 'pacientes': return 'la gestión de pacientes';
      case 'citas': return 'las citas y consultas';
      case 'artículos': return 'la creación de artículos';
      default: return 'esta función';
    }
  }
}