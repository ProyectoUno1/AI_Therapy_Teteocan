// lib/shared/star_rating_display.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;
  final bool showRatingCount;
  final TextStyle? textStyle;
  final MainAxisAlignment mainAxisAlignment;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 16.0,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.showRatingText = true,
    this.showRatingCount = true,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveUtils.isLandscapeMode(context);
    final availableWidth = MediaQuery.of(context).size.width;
    
    // Ajustar tamaño basado en el ancho de pantalla
    final adjustedSize = _getAdjustedSize(availableWidth, isLandscape);
    final spacing = _getSpacing(availableWidth, isLandscape);

    return Container(
      constraints: BoxConstraints(
        maxWidth: _getMaxWidth(availableWidth, isLandscape),
      ),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estrellas con espaciado ajustado
          ...List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Icon(
                _getStarIcon(index + 1, rating),
                size: adjustedSize,
                color: _getStarColor(index + 1, rating),
              ),
            );
          }),
          
          // Espacio entre estrellas y texto
          if (showRatingText || showRatingCount) SizedBox(width: spacing),
          
          // Texto del rating
          if (showRatingText && rating > 0) ...[
            Text(
              rating.toStringAsFixed(1),
              style: textStyle ?? TextStyle(
                fontSize: adjustedSize * 0.8,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          
          // Contador de ratings
          if (showRatingCount && totalRatings > 0) ...[
            if (showRatingText) SizedBox(width: spacing / 2),
            Text(
              '($totalRatings)',
              style: textStyle?.copyWith(
                color: Colors.grey[600],
                fontSize: (textStyle?.fontSize ?? adjustedSize * 0.8) * 0.9,
              ) ?? TextStyle(
                fontSize: adjustedSize * 0.7,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
          
          // Mostrar "Sin calificaciones" si no hay rating
          if (!showRatingText && !showRatingCount && rating == 0) ...[
            Text(
              'Sin calificaciones',
              style: textStyle ?? TextStyle(
                fontSize: adjustedSize * 0.8,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getAdjustedSize(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return size * 0.7; // Pantallas muy pequeñas
    } else if (availableWidth < 375) {
      return size * 0.8; // Pantallas pequeñas (iPhone SE)
    } else if (availableWidth < 414) {
      return size * 0.9; // Pantallas medianas
    } else if (isLandscape) {
      return size * 0.8; // Landscape
    } else {
      return size; // Tamaño normal
    }
  }

  double _getSpacing(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return 1.0; // Espaciado mínimo para pantallas pequeñas
    } else if (availableWidth < 375) {
      return 2.0;
    } else if (isLandscape) {
      return 1.5; // Menos espaciado en landscape
    } else {
      return 3.0; // Espaciado normal
    }
  }

  double _getMaxWidth(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return 120.0; // Ancho máximo muy reducido
    } else if (availableWidth < 375) {
      return 150.0;
    } else if (isLandscape) {
      return 180.0; // Landscape más restrictivo
    } else {
      return 200.0; // Ancho máximo normal
    }
  }

  IconData _getStarIcon(int starNumber, double rating) {
    if (rating >= starNumber) {
      return Icons.star; // Estrella llena
    } else if (rating >= starNumber - 0.5) {
      return Icons.star_half; // Media estrella
    } else {
      return Icons.star_border; // Estrella vacía
    }
  }

  Color _getStarColor(int starNumber, double rating) {
    if (rating >= starNumber - 0.5) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }
}

// Widget alternativo para mostrar solo las estrellas sin texto
class StarsOnlyDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final MainAxisAlignment mainAxisAlignment;

  const StarsOnlyDisplay({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveUtils.isLandscapeMode(context);
    final availableWidth = MediaQuery.of(context).size.width;
    
    final adjustedSize = _getAdjustedSize(availableWidth, isLandscape);
    final spacing = _getSpacing(availableWidth, isLandscape);

    return Container(
      constraints: BoxConstraints(
        maxWidth: _getMaxWidth(availableWidth, isLandscape),
      ),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Icon(
              _getStarIcon(index + 1, rating),
              size: adjustedSize,
              color: _getStarColor(index + 1, rating),
            ),
          );
        }),
      ),
    );
  }

  double _getAdjustedSize(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return size * 0.7;
    } else if (availableWidth < 375) {
      return size * 0.8;
    } else if (availableWidth < 414) {
      return size * 0.9;
    } else if (isLandscape) {
      return size * 0.8;
    } else {
      return size;
    }
  }

  double _getSpacing(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return 1.0;
    } else if (availableWidth < 375) {
      return 2.0;
    } else if (isLandscape) {
      return 1.5;
    } else {
      return 3.0;
    }
  }

  double _getMaxWidth(double availableWidth, bool isLandscape) {
    if (availableWidth < 320) {
      return 100.0;
    } else if (availableWidth < 375) {
      return 120.0;
    } else if (isLandscape) {
      return 140.0;
    } else {
      return 160.0;
    }
  }

  IconData _getStarIcon(int starNumber, double rating) {
    if (rating >= starNumber) {
      return Icons.star;
    } else if (rating >= starNumber - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int starNumber, double rating) {
    if (rating >= starNumber - 0.5) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }
}