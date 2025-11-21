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
      return _buildNoRatings(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 900;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                final shouldUseRow = (isTablet && isLandscape) || 
                                   (!isMobile && showDistribution);

                return Flex(
                  direction: shouldUseRow ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainRating(context, isMobile, isTablet),
                    if (showDistribution && rating!.ratingDistribution != null) ...[
                      SizedBox(
                        width: shouldUseRow ? (isMobile ? 16 : 24) : 0,
                        height: shouldUseRow ? 0 : (isMobile ? 16 : 24),
                      ),
                      if (shouldUseRow)
                        Expanded(
                          child: _buildRatingDistribution(
                            rating!.ratingDistribution!,
                            isMobile,
                            isTablet,
                          ),
                        )
                      else
                        _buildRatingDistribution(
                          rating!.ratingDistribution!,
                          isMobile,
                          isTablet,
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoRatings(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            FractionallySizedBox(
              widthFactor: 0.3,
              child: AspectRatio(
                aspectRatio: 1,
                child: Icon(
                  Icons.star_border,
                  size: isMobile ? 40 : 48,
                  color: Colors.grey[400],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            FittedBox(
              child: Text(
                'Sin calificaciones aún',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              'Sé el primero en calificar a este psicólogo',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
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

  Widget _buildMainRating(BuildContext context, bool isMobile, bool isTablet) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rating!.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: isMobile ? 28 : (isTablet ? 32 : 36),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          StarsOnlyDisplay(
            rating: rating!.averageRating,
            size: isMobile ? 16 : 18,
          ),
          SizedBox(height: isMobile ? 4 : 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${rating!.totalRatings} ${rating!.totalRatings == 1 ? 'reseña' : 'reseñas'}',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(
    Map<int, int> distribution,
    bool isMobile,
    bool isTablet,
  ) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int star = 5; star >= 1; star--) ...[
              _buildDistributionBar(
                star,
                distribution[star] ?? 0,
                total,
                isMobile,
                constraints.maxWidth,
              ),
              if (star > 1) SizedBox(height: isMobile ? 4 : 6),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDistributionBar(
    int star,
    int count,
    int total,
    bool isMobile,
    double maxWidth,
  ) {
    return Row(
      children: [
        SizedBox(
          width: isMobile ? 20 : 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$star',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Icon(
          Icons.star,
          size: isMobile ? 10 : 12,
          color: Colors.amber[600],
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, barConstraints) {
              return LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.amber[600]!,
                ),
                minHeight: isMobile ? 5 : 6,
              );
            },
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        SizedBox(
          width: isMobile ? 20 : 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CompactRatingDisplay extends StatelessWidget {
  final PsychologistRatingModel? rating;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StarRatingDisplay(
              rating: rating?.averageRating ?? 0.0,
              totalRatings: rating?.totalRatings ?? 0,
              size: isMobile ? 12 : 14,
              showRatingText: true,
              showRatingCount: true,
              textStyle: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      },
    );
  }
}