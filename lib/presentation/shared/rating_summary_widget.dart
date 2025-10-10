// lib/presentation/shared/widgets/rating_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';

/// Widget para mostrar resumen de calificaciones
class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;
  final VoidCallback? onViewAllReviews;
  final bool showViewAllButton;
  final bool compact;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    this.onViewAllReviews,
    this.showViewAllButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              StarRatingDisplay(
                rating: averageRating,
                totalRatings: 0,
                size: 14,
                showRatingText: false,
                showRatingCount: false,
              ),
              const SizedBox(height: 4),
              Text(
                '$totalRatings reseñas',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 5; i >= 1; i--)
                  _buildRatingBar(i, ratingDistribution[i] ?? 0, true),
              ],
            ),
          ),
          if (showViewAllButton && onViewAllReviews != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: onViewAllReviews,
              color: AppConstants.lightAccentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              if (showViewAllButton && onViewAllReviews != null)
                TextButton(
                  onPressed: onViewAllReviews,
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      color: AppConstants.lightAccentColor,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    StarRatingDisplay(
                      rating: averageRating,
                      totalRatings: 0,
                      size: 20,
                      showRatingText: false,
                      showRatingCount: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalRatings reseñas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      _buildRatingBar(i, ratingDistribution[i] ?? 0, false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, bool compact) {
    final percentage = totalRatings > 0 ? (count / totalRatings) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            size: compact ? 10 : 12,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.lightAccentColor,
                ),
                minHeight: compact ? 4 : 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: compact ? 20 : 30,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar badge de calificación
class RatingBadge extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double size;

  const RatingBadge({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.5,
          vertical: size * 0.25,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(size * 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline,
              size: size,
              color: Colors.grey[600],
            ),
            SizedBox(width: size * 0.25),
            Text(
              'Sin reseñas',
              style: TextStyle(
                fontSize: size * 0.75,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Color badgeColor;
    if (rating >= 4.5) {
      badgeColor = Colors.green;
    } else if (rating >= 4.0) {
      badgeColor = Colors.lightGreen;
    } else if (rating >= 3.0) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.5,
        vertical: size * 0.25,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.5),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: size,
            color: badgeColor,
          ),
          SizedBox(width: size * 0.25),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.875,
              color: badgeColor,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: size * 0.25),
          Text(
            '($totalReviews)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: badgeColor,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}