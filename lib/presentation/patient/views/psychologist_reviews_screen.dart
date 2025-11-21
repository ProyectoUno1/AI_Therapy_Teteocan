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
  late ScrollController _scrollController;
  bool _showStatsHeader = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadReviews();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final shouldShow = scrollOffset <= 50;

    if (shouldShow != _showStatsHeader) {
      setState(() {
        _showStatsHeader = shouldShow;
      });
    }
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
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;
    
    // Limitar el factor de escala de texto
    final constrainedTextScale = mediaQuery.textScaleFactor.clamp(1.0, 1.2);
    
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaleFactor: constrainedTextScale,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios, 
              color: Colors.black,
              size: isSmallScreen ? 18.0 : 20.0,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reseñas',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isSmallScreen ? 16.0 : 18.0,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                widget.psychologistName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 10.0 : 12.0,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(isSmallScreen)
                : _reviews.isEmpty
                    ? _buildEmptyState(isSmallScreen)
                    : _buildMainLayout(isLandscape, isSmallScreen, isVerySmallScreen),
      ),
    );
  }

  Widget _buildMainLayout(bool isLandscape, bool isSmallScreen, bool isVerySmallScreen) {
    if (isLandscape) {
      return _buildLandscapeLayout(isSmallScreen, isVerySmallScreen);
    } else {
      return _buildPortraitLayout(isSmallScreen, isVerySmallScreen);
    }
  }

  Widget _buildLandscapeLayout(bool isSmallScreen, bool isVerySmallScreen) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          children: [
            // Header de estadísticas
            _buildStatsHeader(isSmallScreen, isVerySmallScreen),
            
            // Filtros
            _buildFilterChips(isSmallScreen, isVerySmallScreen),
            
            // Lista de reseñas
            _buildReviewsContent(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isSmallScreen, bool isVerySmallScreen) {
    return Column(
      children: [
        // Header de estadísticas
        _buildStatsHeader(isSmallScreen, isVerySmallScreen),
        
        // Filtros
        _buildFilterChips(isSmallScreen, isVerySmallScreen),
        
        // Lista de reseñas con scroll
        Expanded(
          child: _buildReviewsList(isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final averageRating = (_stats['averageRating'] ?? 0.0).toDouble();
    final totalRatings = _stats['totalRatings'] ?? 0;
    final distribution = _stats['ratingDistribution'] ?? {};

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    if (isLandscape) {
      // Layout compacto para landscape
      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Row(
          children: [
            // Calificación promedio
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 28.0 : (isSmallScreen ? 32.0 : 36.0),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2.0 : 4.0),
                  StarRatingDisplay(
                    rating: averageRating,
                    totalRatings: 0,
                    size: isSmallScreen ? 14.0 : 16.0,
                    showRatingText: false,
                    showRatingCount: false,
                  ),
                  SizedBox(height: isSmallScreen ? 2.0 : 4.0),
                  Text(
                    '$totalRatings reseñas',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10.0 : 12.0,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            // Distribución de ratings compacta
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 5; i >= 1; i--)
                    _buildCompactRatingBar(
                      i,
                      distribution[i.toString()] ?? 0,
                      totalRatings,
                      isSmallScreen,
                      isVerySmallScreen,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Layout normal para portrait
      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 36.0 : (isSmallScreen ? 42.0 : 48.0),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                      StarRatingDisplay(
                        rating: averageRating,
                        totalRatings: 0,
                        size: isSmallScreen ? 16.0 : 20.0,
                        showRatingText: false,
                        showRatingCount: false,
                      ),
                      SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                      Text(
                        '$totalRatings reseñas',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12.0 : 14.0,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 16.0 : 24.0),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      for (int i = 5; i >= 1; i--)
                        _buildRatingBar(
                          i,
                          distribution[i.toString()] ?? 0,
                          totalRatings,
                          isSmallScreen,
                          isVerySmallScreen,
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
  }

  Widget _buildCompactRatingBar(int stars, int count, int total, bool isSmallScreen, bool isVerySmallScreen) {
    final percentage = total > 0 ? (count / total) : 0.0;
    final fontSize = isVerySmallScreen ? 8.0 : (isSmallScreen ? 9.0 : 10.0);
    final barHeight = isSmallScreen ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          SizedBox(
            width: isVerySmallScreen ? 10.0 : 12.0,
            child: Text(
              '$stars',
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.0),
          Icon(
            Icons.star, 
            size: isSmallScreen ? 8.0 : 10.0, 
            color: Colors.amber
          ),
          SizedBox(width: isSmallScreen ? 2.0 : 4.0),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.lightAccentColor,
                ),
                minHeight: barHeight,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 2.0 : 4.0),
          SizedBox(
            width: isVerySmallScreen ? 16.0 : 20.0,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: fontSize,
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

  Widget _buildRatingBar(int stars, int count, int total, bool isSmallScreen, bool isVerySmallScreen) {
    final percentage = total > 0 ? (count / total) : 0.0;
    final fontSize = isVerySmallScreen ? 10.0 : (isSmallScreen ? 11.0 : 12.0);
    final barHeight = isSmallScreen ? 6.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
      child: Row(
        children: [
          SizedBox(
            width: isVerySmallScreen ? 12.0 : 16.0,
            child: Text(
              '$stars',
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: isSmallScreen ? 2.0 : 4.0),
          Icon(
            Icons.star, 
            size: isSmallScreen ? 10.0 : 12.0, 
            color: Colors.amber
          ),
          SizedBox(width: isSmallScreen ? 4.0 : 8.0),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.lightAccentColor,
                ),
                minHeight: barHeight,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 4.0 : 8.0),
          SizedBox(
            width: isVerySmallScreen ? 20.0 : 30.0,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: fontSize,
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

  Widget _buildFilterChips(bool isSmallScreen, bool isVerySmallScreen) {
    final chipHeight = isSmallScreen ? 36.0 : 44.0;
    final chipFontSize = isSmallScreen ? 10.0 : 12.0;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      color: Colors.white,
      height: isLandscape ? chipHeight - 8.0 : chipHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 16.0, 
        vertical: isSmallScreen ? 4.0 : 6.0
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Todas', 0, chipFontSize),
          for (int i = 5; i >= 1; i--) 
            _buildFilterChip('$i ⭐', i, chipFontSize),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value, double fontSize) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.lightAccentColor,
            fontFamily: 'Poppins',
            fontSize: fontSize,
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
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.8,
          vertical: fontSize * 0.4,
        ),
      ),
    );
  }

  Widget _buildReviewsContent(bool isSmallScreen) {
    final filteredReviews = _filteredReviews;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (filteredReviews.isEmpty) {
      return Container(
        height: isLandscape ? 200.0 : 300.0,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off, 
                size: isSmallScreen ? 40.0 : 48.0, 
                color: Colors.grey[400]
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              Text(
                'No hay reseñas con este filtro',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12.0 : 14.0,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (isLandscape) {
      return _buildLandscapeReviewsList(isSmallScreen, filteredReviews);
    } else {
      return Expanded(child: _buildReviewsList(isSmallScreen));
    }
  }

  Widget _buildLandscapeReviewsList(bool isSmallScreen, List<PsychologistReview> filteredReviews) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 400.0, // Altura mínima para landscape
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(), // Deshabilitar scroll interno
        shrinkWrap: true,
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        itemCount: filteredReviews.length,
        itemBuilder: (context, index) {
          final review = filteredReviews[index];
          return _ReviewCard(
            review: review, 
            isSmallScreen: isSmallScreen
          );
        },
      ),
    );
  }

  Widget _buildReviewsList(bool isSmallScreen) {
    final filteredReviews = _filteredReviews;

    if (filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off, 
              size: isSmallScreen ? 48.0 : 64.0, 
              color: Colors.grey[400]
            ),
            SizedBox(height: isSmallScreen ? 12.0 : 16.0),
            Text(
              'No hay reseñas con este filtro',
              style: TextStyle(
                fontSize: isSmallScreen ? 14.0 : 16.0,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _ReviewCard(
          review: review, 
          isSmallScreen: isSmallScreen
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined, 
            size: isSmallScreen ? 48.0 : 64.0, 
            color: Colors.grey[400]
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          Text(
            'Sin reseñas aún',
            style: TextStyle(
              fontSize: isSmallScreen ? 16.0 : 18.0,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24.0 : 32.0),
            child: Text(
              'Este psicólogo aún no tiene reseñas',
              style: TextStyle(
                fontSize: isSmallScreen ? 12.0 : 14.0,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline, 
            size: isSmallScreen ? 48.0 : 64.0, 
            color: Colors.red[400]
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          Text(
            'Error al cargar reseñas',
            style: TextStyle(
              fontSize: isSmallScreen ? 16.0 : 18.0,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24.0 : 32.0),
            child: Text(
              _error ?? 'Error desconocido',
              style: TextStyle(
                fontSize: isSmallScreen ? 12.0 : 14.0,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          ElevatedButton(
            onPressed: _loadReviews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.lightAccentColor,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20.0 : 24.0,
                vertical: isSmallScreen ? 12.0 : 16.0,
              ),
            ),
            child: Text(
              'Reintentar',
              style: TextStyle(
                fontSize: isSmallScreen ? 14.0 : 16.0,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PsychologistReview review;
  final bool isSmallScreen;

  const _ReviewCard({
    required this.review,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final avatarSize = isLandscape 
        ? (isSmallScreen ? 14.0 : 16.0)
        : (isSmallScreen ? 16.0 : 20.0);
    final nameFontSize = isLandscape
        ? (isSmallScreen ? 10.0 : 12.0)
        : (isSmallScreen ? 12.0 : 14.0);
    final timeFontSize = isLandscape
        ? (isSmallScreen ? 8.0 : 10.0)
        : (isSmallScreen ? 10.0 : 12.0);
    final commentFontSize = isLandscape
        ? (isSmallScreen ? 10.0 : 12.0)
        : (isSmallScreen ? 12.0 : 14.0);
    final starSize = isLandscape
        ? (isSmallScreen ? 12.0 : 14.0)
        : (isSmallScreen ? 14.0 : 16.0);

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6.0 : 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: avatarSize,
                  backgroundImage: review.profile_picture_url != null
                      ? NetworkImage(review.profile_picture_url!)
                      : null,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
                  child: review.profile_picture_url == null
                      ? Icon(
                          Icons.person, 
                          size: avatarSize, 
                          color: Colors.white
                        )
                      : null,
                ),
                SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.patientName,
                        style: TextStyle(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.0),
                      Text(
                        timeago.format(review.ratedAt, locale: 'es'),
                        style: TextStyle(
                          fontSize: timeFontSize,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 4.0 : 6.0),
                StarRatingDisplay(
                  rating: review.rating.toDouble(),
                  totalRatings: 0,
                  size: starSize,
                  showRatingText: false,
                  showRatingCount: false,
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: commentFontSize,
                  color: Colors.grey[800],
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}