// lib/presentation/psychologist/views/psychologist_reviews_screen_psychologist.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_reviews_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:timeago/timeago.dart' as timeago;

class PsychologistReviewsScreenPsychologist extends StatefulWidget {
  const PsychologistReviewsScreenPsychologist({super.key});

  @override
  State<PsychologistReviewsScreenPsychologist> createState() =>
      _PsychologistReviewsScreenPsychologistState();
}

class _PsychologistReviewsScreenPsychologistState
    extends State<PsychologistReviewsScreenPsychologist> {
  List<PsychologistReview> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  int _selectedFilter = 0;
  String? _psychologistId;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    try {
      final authState = context.read<AuthBloc>().state;
      
      if (authState.status != AuthStatus.authenticated ||
          authState.psychologist == null) {
        setState(() {
          _error = 'No se pudo obtener la información del psicólogo';
          _isLoading = false;
        });
        return;
      }

      _psychologistId = authState.psychologist!.uid;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await PsychologistReviewsService.getPsychologistReviews(
        _psychologistId!,
      );

      final stats = await PsychologistReviewsService.getPsychologistRatingStats(
        _psychologistId!,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar las reseñas: ${e.toString()}';
          _isLoading = false;
        });
      }
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
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: ResponsiveUtils.getIconSize(context, 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ResponsiveText(
          'Mis Reseñas',
          baseFontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.black,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
              onPressed: _loadReviews,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            ResponsiveSpacing(16),
            ResponsiveText(
              'Cargando reseñas...',
              baseFontSize: 14,
              color: Colors.grey,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_reviews.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsHeader(),
        _buildFilterChips(),
        Expanded(child: _buildReviewsList()),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final averageRating = (_stats['averageRating'] ?? 0.0).toDouble();
    final totalRatings = _stats['totalRatings'] ?? 0;
    final distribution = _stats['ratingDistribution'] ?? {};
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        children: [
          isMobileSmall
              ? Column(
                  children: [
                    Column(
                      children: [
                        ResponsiveText(
                          averageRating.toStringAsFixed(1),
                          baseFontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        StarRatingDisplay(
                          rating: averageRating,
                          totalRatings: 0,
                          size: 20,
                          showRatingText: false,
                          showRatingCount: false,
                        ),
                        ResponsiveSpacing(8),
                        ResponsiveText(
                          '$totalRatings reseñas',
                          baseFontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    ResponsiveSpacing(24),
                    Column(
                      children: [
                        for (int i = 5; i >= 1; i--)
                          _buildRatingBar(
                            i,
                            distribution[i.toString()] ?? 0,
                            totalRatings,
                          ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ResponsiveText(
                            averageRating.toStringAsFixed(1),
                            baseFontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                          StarRatingDisplay(
                            rating: averageRating,
                            totalRatings: 0,
                            size: 20,
                            showRatingText: false,
                            showRatingCount: false,
                          ),
                          ResponsiveSpacing(8),
                          ResponsiveText(
                            '$totalRatings reseñas',
                            baseFontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                    ResponsiveHorizontalSpacing(24),
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
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getVerticalSpacing(context, 4),
      ),
      child: Row(
        children: [
          ResponsiveText(
            '$stars',
            baseFontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          ResponsiveHorizontalSpacing(4),
          Icon(
            Icons.star,
            size: ResponsiveUtils.getIconSize(context, 12),
            color: Colors.amber,
          ),
          ResponsiveHorizontalSpacing(8),
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
          ResponsiveHorizontalSpacing(8),
          SizedBox(
            width: 30,
            child: ResponsiveText(
              '$count',
              baseFontSize: 12,
              color: Colors.grey[600],
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context),
      ),
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
      padding: EdgeInsets.only(
        right: ResponsiveUtils.getHorizontalSpacing(context, 8),
      ),
      child: FilterChip(
        label: ResponsiveText(
          label,
          baseFontSize: 12,
          color: isSelected ? Colors.white : AppConstants.lightAccentColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    if (filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: ResponsiveUtils.getIconSize(context, 64),
              color: Colors.grey[400],
            ),
            ResponsiveSpacing(16),
            ResponsiveText(
              'No hay reseñas con este filtro',
              baseFontSize: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _ReviewCard(review: review, showAnonymous: true);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getHorizontalPadding(context) * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: ResponsiveUtils.getIconSize(context, 64),
              color: Colors.grey[400],
            ),
            ResponsiveSpacing(16),
            ResponsiveText(
              'Sin reseñas aún',
              baseFontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            ResponsiveSpacing(8),
            ResponsiveText(
              'Completa sesiones con tus pacientes para recibir calificaciones',
              baseFontSize: 14,
              color: Colors.grey[500],
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getHorizontalPadding(context) * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveUtils.getIconSize(context, 64),
              color: Colors.red[400],
            ),
            ResponsiveSpacing(16),
            ResponsiveText(
              'Error al cargar reseñas',
              baseFontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            ResponsiveSpacing(8),
            ResponsiveText(
              _error ?? 'Error desconocido',
              baseFontSize: 14,
              color: Colors.grey[500],
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(16),
            ElevatedButton.icon(
              onPressed: _loadReviews,
              icon: Icon(
                Icons.refresh,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.lightAccentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalSpacing(context, 24),
                  vertical: ResponsiveUtils.getVerticalSpacing(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PsychologistReview review;
  final bool showAnonymous;

  const _ReviewCard({
    required this.review,
    this.showAnonymous = false,
  });

  String _getAnonymousName(String patientName) {
    final hash = patientName.hashCode.abs();
    final adjectives = ['Feliz', 'Tranquilo', 'Valiente', 'Amable', 'Sereno', 'Optimista', 'Sabio'];
    final nouns = ['Usuario', 'Paciente', 'Persona', 'Visitante', 'Miembro', 'Invitado'];
    final adj = adjectives[hash % adjectives.length];
    final noun = nouns[(hash ~/ adjectives.length) % nouns.length];
    return '$adj $noun';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = showAnonymous 
        ? _getAnonymousName(review.patientName)
        : review.patientName;
    
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 12);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    final avatarRadius = ResponsiveUtils.getAvatarRadius(context, 20);

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
                  child: showAnonymous
                      ? Icon(
                          Icons.person,
                          size: ResponsiveUtils.getIconSize(context, 20),
                          color: Colors.white,
                        )
                      : (review.profile_picture_url != null
                          ? ClipOval(
                              child: Image.network(
                                review.profile_picture_url!,
                                width: avatarRadius * 2,
                                height: avatarRadius * 2,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: ResponsiveUtils.getIconSize(context, 20),
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: ResponsiveUtils.getIconSize(context, 20),
                              color: Colors.white,
                            )),
                ),
                ResponsiveHorizontalSpacing(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        displayName,
                        baseFontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      ResponsiveText(
                        timeago.format(review.ratedAt, locale: 'es'),
                        baseFontSize: 12,
                        color: Colors.grey[600],
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
              ResponsiveSpacing(12),
              ResponsiveText(
                review.comment!,
                baseFontSize: 14,
                color: Colors.grey[800],
              ),
            ],
          ],
        ),
      ),
    );
  }
}