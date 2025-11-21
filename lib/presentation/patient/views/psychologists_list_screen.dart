import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/appointment_booking_screen.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_rating_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/psychologist_reviews_screen.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_reviews_service.dart';

class PsychologistsListScreen extends StatefulWidget {
  final bool showAppBar;

  const PsychologistsListScreen({super.key, this.showAppBar = false});

  @override
  State<PsychologistsListScreen> createState() =>
      _PsychologistsListScreenState();
}

class _PsychologistsListScreenState extends State<PsychologistsListScreen> {
  String _searchQuery = '';
  String _selectedSpecialty = 'Todas';

  final List<String> _specialties = [
    'Todas',
    'Depresión',
    'Ansiedad',
    'Terapia de Pareja',
    'Trastornos Alimentarios',
    'Adicciones',
    'Terapia Familiar',
    'Ansiedad y Depresión',
    'Estrés Postraumático',
    'Autoestima',
    'Mindfulness',
    'Psicología Infantil',
    'Psicología Adolescente',
    'Psicología Laboral',
    'Otro',
  ];

  late Future<List<PsychologistModel>> _psychologistsFuture;
  Map<String, PsychologistRatingModel> _ratings = {};
  List<PsychologistModel> _allPsychologists = [];
  List<PsychologistModel> _filteredPsychologists = [];
  bool _isLoadingRatings = false;
  String? _ratingsError;

  @override
  void initState() {
    super.initState();
    _loadPsychologists();
  }

  Future<void> _loadPsychologists() async {
    setState(() {
      _psychologistsFuture = _fetchPsychologistsWithProfessionalInfo();
    });
  }

  Future<List<PsychologistModel>>
  _fetchPsychologistsWithProfessionalInfo() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final psychologistsRef = firestore.collection('psychologists');

      final psychologistsSnapshot = await psychologistsRef
          .where('status', isEqualTo: 'ACTIVE')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (psychologistsSnapshot.docs.isEmpty) {
        return [];
      }

      final combinedPsychologists = await Future.wait(
        psychologistsSnapshot.docs.map((basicDoc) async {
          final uid = basicDoc.id;
          final basicData = basicDoc.data() as Map<String, dynamic>;

          final professionalDoc = await psychologistsRef.doc(uid).get();

          final professionalData = professionalDoc.exists
              ? professionalDoc.data() as Map<String, dynamic>
              : {};

          final Map<String, dynamic> combinedData = {
            ...basicData,
            ...professionalData,
          };

          return PsychologistModel.fromFirestore(combinedData);
        }),
      );

      _allPsychologists = combinedPsychologists;

      await _loadRatings();
      _applyFilters();

      return _allPsychologists;
    } catch (e) {
      return [];
    }
  }

  void _applyFilters() {
    List<PsychologistModel> filtered = _allPsychologists.where((psychologist) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (psychologist.fullName ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (psychologist.specialty?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesSpecialty =
          _selectedSpecialty == 'Todas' ||
          (psychologist.specialty == _selectedSpecialty);

      return matchesSearch && matchesSpecialty;
    }).toList();

    setState(() {
      _filteredPsychologists = filtered;
    });
  }

  Future<void> _loadRatings() async {
    if (_allPsychologists.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingRatings = true;
      _ratingsError = null;
    });

    try {
      final hasConnection = await PsychologistRatingService.testConnection();
      if (!hasConnection) {
        throw Exception('No se pudo conectar al servidor');
      }

      final psychologistIds = _allPsychologists.map((p) => p.uid).toList();
      final ratingsData =
          await PsychologistRatingService.getPsychologistsRatings(
            psychologistIds,
          );

      setState(() {
        _ratings = ratingsData;
        _isLoadingRatings = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRatings = false;
        _ratingsError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando calificaciones: ${e.toString()}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _loadRatings,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenHeight = screenSize.height;
    final isLandscape = ResponsiveUtils.isLandscapeMode(context);
    final isVerySmallScreen = screenHeight < 400;

    return Builder(
      builder: (context) {
        final constrainedTextScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.1);
        
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: constrainedTextScale,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: isLandscape || isVerySmallScreen ? 48 : 56,
              title: Text(
                'Psicólogos Disponibles',
                style: TextStyle(
                  fontSize: isLandscape ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).iconTheme.color,
                  size: isLandscape ? 18 : 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).iconTheme.color,
                    size: isLandscape ? 20 : 24,
                  ),
                  onPressed: _showFilterBottomSheet,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoadingRatings
                        ? Colors.orange
                        : Theme.of(context).iconTheme.color,
                    size: isLandscape ? 20 : 24,
                  ),
                  onPressed: _isLoadingRatings ? null : _loadRatings,
                ),
              ],
            ),
            body: FutureBuilder<List<PsychologistModel>>(
              future: _psychologistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error);
                }

                final psychologists =
                    _filteredPsychologists.isEmpty &&
                        _searchQuery.isEmpty &&
                        _selectedSpecialty == 'Todas'
                    ? _allPsychologists
                    : _filteredPsychologists;

                if (psychologists.isEmpty) {
                  return _buildEmptyState();
                }

                if (isLandscape) {
                  return _buildLandscapeView(psychologists, isVerySmallScreen);
                }

                return _buildPortraitView(psychologists);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeView(List<PsychologistModel> psychologists, bool isVerySmallScreen) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: false,
          floating: true,
          delegate: _SearchHeaderDelegate(
            maxExtent: isVerySmallScreen ? 56 : 64,
            minExtent: 0,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
            isCompact: isVerySmallScreen,
          ),
        ),

        SliverPersistentHeader(
          pinned: false,
          floating: true,
          delegate: _FiltersHeaderDelegate(
            maxExtent: isVerySmallScreen ? 36 : 40,
            minExtent: 0,
            selectedSpecialty: _selectedSpecialty,
            specialties: _specialties,
            onSpecialtyChanged: (specialty) {
              setState(() => _selectedSpecialty = specialty);
              _applyFilters();
            },
            isCompact: isVerySmallScreen,
          ),
        ),

        if (_isLoadingRatings || _ratingsError != null)
          SliverToBoxAdapter(
            child: _buildRatingsBanner(isVerySmallScreen),
          ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final psychologist = psychologists[index];
                final rating = _ratings[psychologist.uid];
                return _PsychologistCard(
                  psychologist: psychologist,
                  rating: rating,
                  onTap: () => _onPsychologistSelected(psychologist),
                  isCompact: true,
                );
              },
              childCount: psychologists.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitView(List<PsychologistModel> psychologists) {
    return Column(
      children: [
        if (_isLoadingRatings || _ratingsError != null) 
          _buildRatingsBanner(false),

        Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchBar(false),
              _buildSpecialtyFilters(false),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: psychologists.length,
            itemBuilder: (context, index) {
              final psychologist = psychologists[index];
              final rating = _ratings[psychologist.uid];
              return _PsychologistCard(
                psychologist: psychologist,
                rating: rating,
                onTap: () => _onPsychologistSelected(psychologist),
                isCompact: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCompact ? 4 : 8,
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Buscar psicólogos...',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontFamily: 'Poppins',
            fontSize: isCompact ? 12 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey,
            size: isCompact ? 18 : 20,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isCompact ? 8 : 12,
          ),
          isDense: isCompact,
        ),
        style: TextStyle(fontSize: isCompact ? 12 : 14),
      ),
    );
  }

  Widget _buildSpecialtyFilters(bool isCompact) {
    return Container(
      height: isCompact ? 36 : 45,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 2 : 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = specialty == _selectedSpecialty;
          return Padding(
            padding: EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                specialty,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 12,
                  color: isSelected ? Colors.white : AppConstants.lightAccentColor,
                ),
              ),
              selected: isSelected,
              selectedColor: AppConstants.lightAccentColor,
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.1),
              onSelected: (selected) {
                setState(() => _selectedSpecialty = specialty);
                _applyFilters();
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 0 : 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingsBanner(bool isCompact) {
    return Container(
      width: double.infinity,
      color: _ratingsError != null
          ? Theme.of(context).colorScheme.error.withOpacity(0.1)
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCompact ? 4 : 8,
      ),
      child: Row(
        children: [
          if (_isLoadingRatings)
            SizedBox(
              width: isCompact ? 12 : 16,
              height: isCompact ? 12 : 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.warning,
              size: isCompact ? 14 : 16,
              color: Colors.red[600],
            ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _isLoadingRatings
                  ? 'Cargando calificaciones...'
                  : 'Error: $_ratingsError',
              style: TextStyle(fontSize: isCompact ? 10 : 12),
            ),
          ),
          if (_ratingsError != null)
            TextButton(
              onPressed: _loadRatings,
              child: Text(
                'Reintentar',
                style: TextStyle(fontSize: isCompact ? 10 : 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          SizedBox(height: 16),
          Text('Error de conexión', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'No se pudieron cargar los psicólogos',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPsychologists,
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No se encontraron psicólogos', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros de búsqueda',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Disponibilidad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('Disponible ahora'),
                    onSelected: (selected) {},
                  ),
                  FilterChip(label: Text('Todas'), onSelected: (selected) {}),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.lightAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Aplicar Filtros',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onPsychologistSelected(PsychologistModel psychologist) {
    _showPsychologistDetailsModal(psychologist);
  }

  void _showPsychologistDetailsModal(PsychologistModel psychologist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return _PsychologistDetailsModal(
              psychologist: psychologist,
              scrollController: scrollController,
              rating: _ratings[psychologist.uid],
              onViewReviews: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PsychologistReviewsScreen(
                      psychologistId: psychologist.uid,
                      psychologistName: psychologist.fullName ?? 'Psicólogo',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Delegado del header de búsqueda
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double _maxExtent;
  final double _minExtent;
  final ValueChanged<String> onSearchChanged;
  final bool isCompact;

  _SearchHeaderDelegate({
    required double maxExtent,
    required double minExtent,
    required this.onSearchChanged,
    required this.isCompact,
  })  : _maxExtent = maxExtent,
        _minExtent = minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final visibleFraction = 1.0 - (shrinkOffset / _maxExtent).clamp(0.0, 1.0);

    return Opacity(
      opacity: visibleFraction,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 4 : 8,
        ),
        child: TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar psicólogos...',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontFamily: 'Poppins',
              fontSize: isCompact ? 12 : 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey,
              size: isCompact ? 18 : 20,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isCompact ? 8 : 12,
            ),
            isDense: isCompact,
          ),
          style: TextStyle(fontSize: isCompact ? 12 : 14),
        ),
      ),
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate._maxExtent != _maxExtent ||
      oldDelegate._minExtent != _minExtent ||
      oldDelegate.isCompact != isCompact;
}

// Delegado del header de filtros
class _FiltersHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double _maxExtent;
  final double _minExtent;
  final String selectedSpecialty;
  final List<String> specialties;
  final ValueChanged<String> onSpecialtyChanged;
  final bool isCompact;

  _FiltersHeaderDelegate({
    required double maxExtent,
    required double minExtent,
    required this.selectedSpecialty,
    required this.specialties,
    required this.onSpecialtyChanged,
    required this.isCompact,
  })  : _maxExtent = maxExtent,
        _minExtent = minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final visibleFraction = 1.0 - (shrinkOffset / _maxExtent).clamp(0.0, 1.0);

    return Opacity(
      opacity: visibleFraction,
      child: Container(
        color: Colors.white,
        height: _maxExtent,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 2 : 4,
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: specialties.length,
          itemBuilder: (context, index) {
            final specialty = specialties[index];
            final isSelected = specialty == selectedSpecialty;
            return Padding(
              padding: EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                  specialty,
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 12,
                    color: isSelected
                        ? Colors.white
                        : AppConstants.lightAccentColor,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppConstants.lightAccentColor,
                backgroundColor:
                    AppConstants.lightAccentColor.withOpacity(0.1),
                onSelected: (selected) => onSpecialtyChanged(specialty),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 6 : 8,
                  vertical: isCompact ? 0 : 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _FiltersHeaderDelegate oldDelegate) =>
      selectedSpecialty != oldDelegate.selectedSpecialty ||
      oldDelegate._maxExtent != _maxExtent ||
      oldDelegate._minExtent != _minExtent ||
      oldDelegate.isCompact != isCompact;
}

// Tarjeta de psicólogo
class _PsychologistCard extends StatelessWidget {
  final PsychologistModel psychologist;
  final PsychologistRatingModel? rating;
  final VoidCallback onTap;
  final bool isCompact;

  const _PsychologistCard({
    required this.psychologist,
    this.rating,
    required this.onTap,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    // Convertir el precio a double de forma segura
    final price = (psychologist.price ?? 0.0).toDouble();

    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isCompact ? 20 : 25,
                backgroundImage: psychologist.profilePictureUrl != null
                    ? NetworkImage(psychologist.profilePictureUrl!)
                    : null,
                backgroundColor:
                    AppConstants.lightAccentColor.withOpacity(0.3),
                child: psychologist.profilePictureUrl == null
                    ? Icon(
                        Icons.person,
                        size: isCompact ? 20 : 25,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      psychologist.fullName ?? 'Psicólogo sin nombre',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      psychologist.specialty ?? 'Especialidad no especificada',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 14,
                        color: AppConstants.lightAccentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    StarRatingDisplay(
                      rating: rating?.averageRating ?? 0.0,
                      totalRatings: rating?.totalRatings ?? 0,
                      size: isCompact ? 11 : 14,
                      showRatingText: true,
                      showRatingCount: !isCompact,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${price.toInt()}',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/hora',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      color: Colors.grey,
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
}

class _PsychologistDetailsModal extends StatelessWidget {
  final PsychologistModel psychologist;
  final ScrollController scrollController;
  final PsychologistRatingModel? rating;
  final VoidCallback onViewReviews;

  const _PsychologistDetailsModal({
    required this.psychologist,
    required this.scrollController,
    this.rating,
    required this.onViewReviews,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = ResponsiveUtils.isLandscapeMode(context);
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: mediaQuery.size.height * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con información del psicólogo
                    _buildPsychologistHeader(context, isLandscape, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Descripción
                    _buildDescriptionSection(isLandscape, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Información de horarios y precio - MEJORADO PARA EVITAR OVERFLOW
                    _buildInfoCards(context, isLandscape, isSmallScreen),
                    
                    // Reseñas recientes
                    if ((rating?.totalRatings ?? 0) > 0) 
                      _buildRecentReviewsSection(context, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 16 : 32),
                    
                    // Botón de agendar cita
                    _buildBookAppointmentButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsychologistHeader(BuildContext context, bool isLandscape, bool isSmallScreen) {
    final avatarSize = isSmallScreen ? 32.0 : (isLandscape ? 32.0 : 40.0);
    final nameFontSize = isSmallScreen ? 16.0 : (isLandscape ? 16.0 : 20.0);
    final specialtyFontSize = isSmallScreen ? 13.0 : (isLandscape ? 13.0 : 16.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: avatarSize,
          backgroundImage: psychologist.profilePictureUrl != null
              ? NetworkImage(psychologist.profilePictureUrl!)
              : null,
          backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
          child: psychologist.profilePictureUrl == null
              ? Icon(
                  Icons.person,
                  size: avatarSize,
                  color: Colors.white,
                )
              : null,
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre con auto-ajuste
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  psychologist.fullName ?? 'Psicólogo sin nombre',
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 4),
              // Especialidad con auto-ajuste
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  psychologist.specialty ?? 'Especialidad general',
                  style: TextStyle(
                    fontSize: specialtyFontSize,
                    color: AppConstants.lightAccentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              // Rating y botón de ver reseñas
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: StarRatingDisplay(
                      rating: rating?.averageRating ?? 0.0,
                      totalRatings: rating?.totalRatings ?? 0,
                      size: isSmallScreen ? 12.0 : (isLandscape ? 14.0 : 16.0),
                      showRatingText: true,
                      showRatingCount: !isLandscape,
                    ),
                  ),
                  if ((rating?.totalRatings ?? 0) > 0) ...[
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: onViewReviews,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ver todas',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.0 : 12.0,
                              color: AppConstants.lightAccentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(bool isLandscape, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre el profesional',
          style: TextStyle(
            fontSize: isSmallScreen ? 15.0 : (isLandscape ? 15.0 : 18.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          psychologist.description ?? 'Descripción no disponible',
          style: TextStyle(
            fontSize: isSmallScreen ? 12.0 : (isLandscape ? 12.0 : 14.0),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(BuildContext context, bool isLandscape, bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isVeryNarrow = availableWidth < 300;
        final isExtremelyNarrow = availableWidth < 250;
        
        if (isExtremelyNarrow) {
          // Para pantallas extremadamente estrechas, mostrar en columna con scroll
          return Column(
            children: [
              _ScheduleInfoCard(
                scheduleText: _getScheduleText(),
                isLandscape: isLandscape,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: 12),
              _PriceInfoCard(
                price: (psychologist.price ?? 0.0).toDouble(),
                isLandscape: isLandscape,
                isSmallScreen: isSmallScreen,
              ),
            ],
          );
        } else if (isVeryNarrow) {
          // Para pantallas muy estrechas, mostrar en columna
          return Column(
            children: [
              _ScheduleInfoCard(
                scheduleText: _getScheduleText(),
                isLandscape: isLandscape,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: 12),
              _PriceInfoCard(
                price: (psychologist.price ?? 0.0).toDouble(),
                isLandscape: isLandscape,
                isSmallScreen: isSmallScreen,
              ),
            ],
          );
        } else {
          // Para pantallas normales, mostrar en fila
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ScheduleInfoCard(
                  scheduleText: _getScheduleText(),
                  isLandscape: isLandscape,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _PriceInfoCard(
                  price: (psychologist.price ?? 0.0).toDouble(),
                  isLandscape: isLandscape,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  String _getScheduleText() {
    if (psychologist.schedule != null && psychologist.schedule!.isNotEmpty) {
      final scheduleEntries = psychologist.schedule!.entries.take(2); // Reducido a 2 días
      final scheduleList = scheduleEntries.map((entry) {
        final day = _getShortDayName(entry.key);
        final scheduleForDay = entry.value as Map<String, dynamic>;
        final startTime = scheduleForDay['startTime'] ?? '';
        final endTime = scheduleForDay['endTime'] ?? '';
        return '$day: $startTime-$endTime';
      }).toList();
      
      // Si hay más de 2 días, agregar "..."
      if (psychologist.schedule!.length > 2) {
        scheduleList.add('...');
      }
      
      return scheduleList.join('\n');
    }
    return 'Horario no definido';
  }

  String _getShortDayName(String fullDayName) {
    final dayMap = {
      'Lunes': 'Lun',
      'Martes': 'Mar',
      'Miércoles': 'Mié',
      'Miercoles': 'Mié',
      'Jueves': 'Jue',
      'Viernes': 'Vie',
      'Sábado': 'Sáb',
      'Sabado': 'Sáb',
      'Domingo': 'Dom',
    };
    return dayMap[fullDayName] ?? fullDayName.substring(0, 3);
  }

  Widget _buildRecentReviewsSection(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 16 : 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Últimas Reseñas',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16.0 : 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: onViewReviews,
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12.0 : 14.0,
                      color: AppConstants.lightAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        _RecentReviewsPreview(psychologistId: psychologist.uid),
      ],
    );
  }

  Widget _buildBookAppointmentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider<AppointmentBloc>(
                create: (context) => AppointmentBloc(),
                child: AppointmentBookingScreen(
                  psychologist: psychologist,
                ),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.lightAccentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Agendar Cita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Card especializada para horarios con mejor manejo de texto
class _ScheduleInfoCard extends StatelessWidget {
  final String scheduleText;
  final bool isLandscape;
  final bool isSmallScreen;

  const _ScheduleInfoCard({
    required this.scheduleText,
    required this.isLandscape,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 18.0 : (isLandscape ? 20.0 : 24.0);
    final titleFontSize = isSmallScreen ? 10.0 : (isLandscape ? 10.0 : 12.0);
    final subtitleFontSize = isSmallScreen ? 9.0 : (isLandscape ? 10.0 : 12.0);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color: AppConstants.lightAccentColor,
            size: iconSize,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'Horarios',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? 40 : 60,
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Text(
                scheduleText,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card especializada para precio
class _PriceInfoCard extends StatelessWidget {
  final double price;
  final bool isLandscape;
  final bool isSmallScreen;

  const _PriceInfoCard({
    required this.price,
    required this.isLandscape,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 18.0 : (isLandscape ? 20.0 : 24.0);
    final titleFontSize = isSmallScreen ? 10.0 : (isLandscape ? 10.0 : 12.0);
    final subtitleFontSize = isSmallScreen ? 11.0 : (isLandscape ? 11.0 : 14.0);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_money,
            color: AppConstants.lightAccentColor,
            size: iconSize,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'Precio',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            '\$${price.toInt()}/hora',
            style: TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentReviewsPreview extends StatefulWidget {
  final String psychologistId;

  const _RecentReviewsPreview({required this.psychologistId});

  @override
  State<_RecentReviewsPreview> createState() => _RecentReviewsPreviewState();
}

class _RecentReviewsPreviewState extends State<_RecentReviewsPreview> {
  List<PsychologistReview> _recentReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentReviews();
  }

  Future<void> _loadRecentReviews() async {
    try {
      final reviews = await PsychologistReviewsService.getPsychologistReviews(
        widget.psychologistId,
      );

      if (mounted) {
        setState(() {
          _recentReviews = reviews.take(2).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_recentReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _recentReviews.map((review) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: review.profile_picture_url != null
                        ? NetworkImage(review.profile_picture_url!)
                        : null,
                    backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
                    child: review.profile_picture_url == null
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.patientName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StarRatingDisplay(
                          rating: review.rating.toDouble(),
                          totalRatings: 0,
                          size: 12.0,
                          showRatingText: false,
                          showRatingCount: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  review.comment!.length > 100
                      ? '${review.comment!.substring(0, 100)}...'
                      : review.comment!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}