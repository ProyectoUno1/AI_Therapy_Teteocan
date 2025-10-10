// lib/presentation/psychologist/widgets/article_limit_card.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
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
                  Row(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artículos creados',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
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
                          ),
                        ],
                      ),
                    ],
                  ),
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

  // Métodos auxiliares
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

// Widget compacto para el header
class ArticleLimitBadge extends StatelessWidget {
  final ArticleLimitInfo limitInfo;

  const ArticleLimitBadge({
    Key? key,
    required this.limitInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canCreate = limitInfo.canCreateMore;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: canCreate
            ? AppConstants.secondaryColor.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canCreate
              ? AppConstants.secondaryColor.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canCreate ? Icons.check_circle : Icons.warning_amber,
            size: 14,
            color: canCreate ? AppConstants.secondaryColor : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            '${limitInfo.currentCount}/${limitInfo.maxLimit}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: canCreate ? AppConstants.secondaryColor : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}