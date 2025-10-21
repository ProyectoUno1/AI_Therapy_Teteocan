// lib/shared/star_rating_display.dart

import 'package:flutter/material.dart';

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;
  final bool showRatingCount;
  final TextStyle? textStyle;

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
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estrellas
        ...List.generate(5, (index) {
          return Icon(
            _getStarIcon(index + 1, rating),
            size: size,
            color: _getStarColor(index + 1, rating),
          );
        }),
        
        if (showRatingText || showRatingCount) const SizedBox(width: 4),
        
        // Texto del rating
        if (showRatingText && rating > 0) ...[
          Text(
            rating.toStringAsFixed(1),
            style: textStyle ?? TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
        
        // Contador de ratings
        if (showRatingCount && totalRatings > 0) ...[
          if (showRatingText) const SizedBox(width: 2),
          Text(
            '($totalRatings)',
            style: textStyle?.copyWith(
              color: Colors.grey[600],
              fontSize: (textStyle?.fontSize ?? size * 0.8) * 0.9,
            ) ?? TextStyle(
              fontSize: size * 0.7,
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
              fontSize: size * 0.8,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
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

  const StarsOnlyDisplay({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          _getStarIcon(index + 1, rating),
          size: size,
          color: _getStarColor(index + 1, rating),
        );
      }),
    );
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