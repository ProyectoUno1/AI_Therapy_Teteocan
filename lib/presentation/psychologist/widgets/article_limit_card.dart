// lib/presentation/psychologist/widgets/article_limit_card.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/data/models/article_limit_info.dart';

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

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

    // ENVOLVER EN MediaQuery PARA CONTROLAR EL TEXT SCALE FACTOR
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: Card(
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
                    // Lado izquierdo: Icono y Texto
                    Expanded(
                      child: Row(
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
                          Expanded(
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
                                  overflow: TextOverflow.ellipsis, 
                                  maxLines: 1, 
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${limitInfo.remaining} disponible${limitInfo.remaining != 1 ? 's' : ''}',
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
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Lado derecho: Contador de límite
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Información adicional
                Row(
                  children: [
                    Icon(
                      isAtLimit ? Icons.warning_amber : Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
      ),
    );
  }

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

class ArticleLimitBadge extends StatelessWidget {
  final ArticleLimitInfo limitInfo;

  const ArticleLimitBadge({super.key, required this.limitInfo});

  @override
  Widget build(BuildContext context) {
    // ENVOLVER EN MediaQuery PARA CONTROLAR EL TEXT SCALE FACTOR
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: Container(
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
            Flexible(
              child: Text(
                '${limitInfo.currentCount}/${limitInfo.maxLimit}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: limitInfo.canCreateMore ? Colors.green : Colors.orange,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}