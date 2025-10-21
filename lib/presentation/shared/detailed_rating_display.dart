// lib/shared/detailed_rating_display.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_rating_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';

class DetailedRatingDisplay extends StatelessWidget {
  final PsychologistRatingModel? rating;
  final bool showDistribution;

  const DetailedRatingDisplay({
    super.key,
    required this.rating,
    this.showDistribution = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating!.averageRating == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.star_border,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Sin calificaciones aún',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sé el primero en calificar a este psicólogo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating principal
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    StarsOnlyDisplay(
                      rating: rating!.averageRating,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rating!.totalRatings} ${rating!.totalRatings == 1 ? 'reseña' : 'reseñas'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                if (showDistribution && rating!.ratingDistribution != null) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildRatingDistribution(rating!.ratingDistribution!),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution(Map<int, int> distribution) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        for (int star = 5; star >= 1; star--) ...[
          Row(
            children: [
              Text(
                '$star',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 12,
                color: Colors.amber[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? (distribution[star] ?? 0) / total : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber[600]!,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${distribution[star] ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          if (star > 1) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// Widget mostrar solo el rating general
class CompactRatingDisplay extends StatelessWidget {
  final PsychologistRatingModel? rating;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: StarRatingDisplay(
        rating: rating?.averageRating ?? 0.0,
        totalRatings: rating?.totalRatings ?? 0,
        size: 14,
        showRatingText: true,
        showRatingCount: true,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}