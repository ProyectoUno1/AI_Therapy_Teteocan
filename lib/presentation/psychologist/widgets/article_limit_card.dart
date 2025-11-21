// lib/presentation/psychologist/widgets/article_limit_card.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/data/models/article_limit_info.dart';

class ArticleLimitCard extends StatelessWidget {
  final ArticleLimitInfo limitInfo;
  final VoidCallback? onTapDetails;

  const ArticleLimitCard({
    Key? key,
    required this.limitInfo,
    this.onTapDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = limitInfo.percentage;
    final isNearLimit = percentage >= 80;
    final isAtLimit = percentage >= 100;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTapDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono y contador
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lado izquierdo: Icono y Texto (LIMITADO)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✅ SOLUCIÓN CLAVE: Usamos ConstrainedBox para limitar el ancho de la columna de texto.
                      // Esto previene el overflow sin requerir límites de ancho definidos del widget padre.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          // Establece un ancho máximo del 50% de la pantalla para dejar espacio al contador.
                          // Resta 32 (padding horizontal de Card) y una pequeña holgura.
                          maxWidth: MediaQuery.of(context).size.width * 0.5 - 20, 
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Artículos creados',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              // ✅ Trunca el texto si es muy largo
                              overflow: TextOverflow.ellipsis, 
                              maxLines: 1, 
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${limitInfo.remaining} disponibles',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Poppins',
                                color: limitInfo.remaining > 0 
                                    ? Colors.green 
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, 
                              maxLines: 1, 
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Lado derecho: Contador de límite (fijo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${limitInfo.currentCount}/${limitInfo.maxLimit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Información adicional (se mantiene Expanded aquí ya que funciona correctamente)
              Row(
                children: [
                  Icon(
                    isAtLimit ? Icons.warning_amber : Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded( // Esto asegura que el texto ocupe el espacio restante y se trunque si es necesario
                    child: Text(
                      _getDetailMessage(),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis, 
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares (sin cambios)
  Color _getStatusColor() {
    if (limitInfo.percentage >= 100) return Colors.red;
    if (limitInfo.percentage >= 80) return Colors.orange;
    return AppConstants.secondaryColor;
  }

  IconData _getStatusIcon() {
    if (limitInfo.percentage >= 100) return Icons.block;
    if (limitInfo.percentage >= 80) return Icons.warning_amber;
    return Icons.article;
  }

  String _getDetailMessage() {
    if (limitInfo.canCreateMore) {
      return 'Puedes crear ${limitInfo.remaining} artículo${limitInfo.remaining != 1 ? 's' : ''} más';
    } else {
      return 'Elimina algunos artículos para crear nuevos';
    }
  }
}

// ArticleLimitBadge (sin cambios)
class ArticleLimitBadge extends StatelessWidget {
  final ArticleLimitInfo limitInfo;

  const ArticleLimitBadge({super.key, required this.limitInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: limitInfo.canCreateMore 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: limitInfo.canCreateMore ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            limitInfo.canCreateMore ? Icons.check_circle : Icons.warning,
            size: 12,
            color: limitInfo.canCreateMore ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '${limitInfo.currentCount}/${limitInfo.maxLimit}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: limitInfo.canCreateMore ? Colors.green : Colors.orange,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}