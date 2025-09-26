// lib/presentation/shared/approval_status_blocker.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';

class ApprovalStatusBlocker extends StatelessWidget {
  final PsychologistModel? psychologist;
  final Widget child;
  final String featureName; // "chats", "pacientes", "citas"

  const ApprovalStatusBlocker({
    super.key,
    required this.psychologist,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay información del psicólogo o está aprobado/activo, mostrar contenido normal
    if (psychologist == null || _isApproved()) {
      return child;
    }

    // Si está pendiente o rechazado, mostrar bloqueo
    return _buildBlockedContent(context);
  }

  // Método para verificar si el psicólogo está aprobado
  bool _isApproved() {
    return psychologist!.status == 'ACTIVE' ||
        (psychologist!.isApproved ?? false);
  }

  Widget _buildBlockedContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de estado
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  size: 60,
                  color: _getStatusColor(),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                _getBlockTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                _getBlockDescription(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Estado actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      psychologist!.statusDisplayText ??
                          _getDefaultStatusText(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botones de acción
              if (_isPending() && !psychologist!.professionalInfoCompleted)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalInfoSetupScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Completar Perfil Profesional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              else if (_isRejected())
                Column(
                  children: [
                    // Mostrar motivo del rechazo si existe
                    if (psychologist!.rejectionReason != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
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
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              psychologist!.rejectionReason!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfessionalInfoSetupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Corregir y Reenviar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tu perfil está siendo revisado...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares para verificar estados
  bool _isPending() {
    return psychologist!.status == 'PENDING';
  }

  bool _isRejected() {
    return psychologist!.status == 'REJECTED';
  }

  Color _getStatusColor() {
    switch (psychologist!.status) {
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'ACTIVE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? Icons.hourglass_empty
            : Icons.edit_note;
      case 'REJECTED':
        return Icons.cancel;
      case 'ACTIVE':
        return Icons.check_circle;
      default:
        return Icons.lock;
    }
  }

  String _getStatusText() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? 'EN REVISIÓN'
            : 'PENDIENTE';
      case 'REJECTED':
        return 'RECHAZADO';
      case 'ACTIVE':
        return 'ACTIVO';
      default:
        return 'BLOQUEADO';
    }
  }

  String _getDefaultStatusText() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? 'Perfil en revisión'
            : 'Perfil incompleto';
      case 'REJECTED':
        return 'Perfil rechazado';
      case 'ACTIVE':
        return 'Perfil aprobado';
      default:
        return 'Estado desconocido';
    }
  }

  String _getBlockTitle() {
    switch (psychologist!.status) {
      case 'PENDING':
        return psychologist!.professionalInfoCompleted
            ? 'Tu perfil está en revisión'
            : 'Completa tu perfil profesional';
      case 'REJECTED':
        return 'Tu perfil fue rechazado';
      default:
        return 'Acceso restringido';
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
      case 'chats':
        return 'los chats con pacientes';
      case 'pacientes':
        return 'la gestión de pacientes';
      case 'citas':
        return 'las citas y consultas';
      default:
        return 'esta función';
    }
  }
}
