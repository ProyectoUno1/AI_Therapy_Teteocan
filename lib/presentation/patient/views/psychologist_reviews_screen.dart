// lib/presentation/patient/views/psychologist_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_reviews_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';
import 'package:timeago/timeago.dart' as timeago;

class PsychologistReviewsScreen extends StatefulWidget {
  final String psychologistId;
  final String psychologistName;

  const PsychologistReviewsScreen({
    super.key,
    required this.psychologistId,
    required this.psychologistName,
  });

  @override
  State<PsychologistReviewsScreen> createState() =>
      _PsychologistReviewsScreenState();
}

class _PsychologistReviewsScreenState extends State<PsychologistReviewsScreen> {
  List<PsychologistReview> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await PsychologistReviewsService.getPsychologistReviews(
        widget.psychologistId,
      );
      final stats = await PsychologistReviewsService.getPsychologistRatingStats(
        widget.psychologistId,
      );

      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PsychologistReview> get _filteredReviews {
    if (_selectedFilter == 0) {
      return _reviews;
    }
    return _reviews.where((review) => review.rating == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reseñas',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              widget.psychologistName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _reviews.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildStatsHeader(),
                        _buildFilterChips(),
                        Expanded(child: _buildReviewsList()),
                      ],
                    ),
    );
  }

  Widget _buildStatsHeader() {
    final averageRating = (_stats['averageRating'] ?? 0.0).toDouble();
    final totalRatings = _stats['totalRatings'] ?? 0;
    final distribution = _stats['ratingDistribution'] ?? {};

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                      _buildRatingBar(
                        i,
                        distribution[i.toString()] ?? 0,
                        totalRatings,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
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
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
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

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Todas', 0),
          for (int i = 5; i >= 1; i--) _buildFilterChip('$i ⭐', i),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.lightAccentColor,
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppConstants.lightAccentColor,
        backgroundColor: AppConstants.lightAccentColor.withOpacity(0.1),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
      ),
    );
  }

  Widget _buildReviewsList() {
    final filteredReviews = _filteredReviews;

    if (filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay reseñas con este filtro',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _ReviewCard(review: review);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin reseñas aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este psicólogo aún no tiene reseñas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar reseñas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Error desconocido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.lightAccentColor,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PsychologistReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.profile_picture_url != null
                      ? NetworkImage(review.profile_picture_url!)
                      : null,
                  backgroundColor:
                      AppConstants.lightAccentColor.withOpacity(0.2),
                  child: review.profile_picture_url == null
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.patientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        timeago.format(review.ratedAt, locale: 'es'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                StarRatingDisplay(
                  rating: review.rating.toDouble(),
                  totalRatings: 0,
                  size: 16,
                  showRatingText: false,
                  showRatingCount: false,
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}