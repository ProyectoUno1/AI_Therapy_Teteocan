// lib/presentation/patient/views/psychologists_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/psychologist_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/appointment_booking_screen.dart';
import 'package:ai_therapy_teteocan/core/services/psychologist_rating_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/star_rating_display.dart';

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
    _psychologistsFuture = _fetchPsychologistsWithProfessionalInfo();
  }

  Future<List<PsychologistModel>>
  _fetchPsychologistsWithProfessionalInfo() async {
    try {
      print('Iniciando carga de psicólogos...');

      final firestore = FirebaseFirestore.instance;
      final psychologistsRef = firestore.collection('psychologists');
      final professionalInfoRef = firestore.collection('psychologists');

      final psychologistsSnapshot = await psychologistsRef.get();

      if (psychologistsSnapshot.docs.isEmpty) {
        print('No se encontraron psicólogos en Firestore');
        return [];
      }

      print('Encontrados ${psychologistsSnapshot.docs.length} psicólogos');

      final combinedPsychologists = await Future.wait(
        psychologistsSnapshot.docs.map((basicDoc) async {
          final uid = basicDoc.id;
          final basicData = basicDoc.data() as Map<String, dynamic>;

          final professionalDoc = await professionalInfoRef.doc(uid).get();

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
      print('Psicólogos cargados: ${_allPsychologists.length}');

      // Cargar ratings después de obtener los psicólogos
      await _loadRatings();

      _applyFilters();
      return _allPsychologists;
    } catch (e) {
      print('Error al obtener la lista de psicólogos: $e');
      return [];
    }
  }

  Future<void> _loadRatings() async {
    if (_allPsychologists.isEmpty) {
      print('No hay psicólogos para cargar ratings');
      return;
    }

    setState(() {
      _isLoadingRatings = true;
      _ratingsError = null;
    });

    try {
      print('Cargando ratings para ${_allPsychologists.length} psicólogos...');

      // Primero probar conectividad
      final hasConnection = await PsychologistRatingService.testConnection();
      if (!hasConnection) {
        throw Exception('No se pudo conectar al servidor');
      }

      final psychologistIds = _allPsychologists.map((p) => p.uid).toList();
      print('IDs a consultar: $psychologistIds');

      final ratingsData =
          await PsychologistRatingService.getPsychologistsRatings(
            psychologistIds,
          );

      setState(() {
        _ratings = ratingsData;
        _isLoadingRatings = false;
      });

      print('Ratings cargados: ${_ratings.length}');

      // Debug: Mostrar algunos ratings
      _ratings.forEach((id, rating) {
        if (rating.totalRatings > 0) {
          print(
            '$id: ${rating.averageRating} (${rating.totalRatings} reseñas)',
          );
        }
      });
    } catch (e) {
      print('Error cargando ratings: $e');
      setState(() {
        _isLoadingRatings = false;
        _ratingsError = e.toString();
      });

      // Mostrar SnackBar con el error
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

  void _applyFilters() {
    setState(() {
      _filteredPsychologists = _allPsychologists.where((psychologist) {
        final matchesSearch =
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Psicólogos Disponibles',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterBottomSheet,
          ),
          // Debug button para recargar ratings
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _isLoadingRatings ? Colors.orange : Colors.black,
            ),
            onPressed: _isLoadingRatings ? null : _loadRatings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de estado de ratings
          if (_isLoadingRatings || _ratingsError != null)
            Container(
              width: double.infinity,
              color: _ratingsError != null ? Colors.red[50] : Colors.blue[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_isLoadingRatings)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.warning, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingRatings
                          ? 'Cargando calificaciones...'
                          : 'Error: $_ratingsError',
                      style: TextStyle(
                        fontSize: 12,
                        color: _ratingsError != null
                            ? Colors.red[600]
                            : Colors.blue[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (_ratingsError != null)
                    TextButton(
                      onPressed: _loadRatings,
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Buscar psicólogos o especialidades...',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                final isSelected = specialty == _selectedSpecialty;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      specialty,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppConstants.lightAccentColor,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppConstants.lightAccentColor,
                    backgroundColor: AppConstants.lightAccentColor.withOpacity(
                      0.1,
                    ),
                    onSelected: (selected) {
                      _selectedSpecialty = specialty;
                      _applyFilters();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<PsychologistModel>>(
              future: _psychologistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text('Ocurrió un error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _psychologistsFuture =
                                  _fetchPsychologistsWithProfessionalInfo();
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || _filteredPsychologists.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPsychologists.length,
                  itemBuilder: (context, index) {
                    final psychologist = _filteredPsychologists[index];
                    final rating = _ratings[psychologist.uid];
                    return _PsychologistCard(
                      psychologist: psychologist,
                      rating: rating,
                      onTap: () => _onPsychologistSelected(psychologist),
                    );
                  },
                );
              },
            ),
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
          const SizedBox(height: 16),
          Text(
            'No se encontraron psicólogos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros de búsqueda',
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Disponibilidad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Disponible ahora'),
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Todas'),
                    onSelected: (selected) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.lightAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
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
    if (psychologist.isAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${psychologist.fullName} no está disponible en este momento',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    _showPsychologistDetailsModal(psychologist);
  }

  void _showPsychologistDetailsModal(PsychologistModel psychologist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
              onStartChat: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PsychologistChatScreen(
                      psychologistUid: psychologist.uid,
                      psychologistName: psychologist.fullName ?? 'Psicólogo',
                      psychologistImageUrl:
                          psychologist.profilePictureUrl ?? '',
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

class _PsychologistCard extends StatelessWidget {
  final PsychologistModel psychologist;
  final PsychologistRatingModel? rating;
  final VoidCallback onTap;

  const _PsychologistCard({
    required this.psychologist,
    this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: psychologist.profilePictureUrl != null
                    ? NetworkImage(psychologist.profilePictureUrl!)
                    : null,
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                child: psychologist.profilePictureUrl == null
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psychologist.fullName ?? 'Psicólogo sin nombre',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      psychologist.specialty ?? 'Especialidad no especificada',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.lightAccentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mostrar rating con información de debug
                    Row(
                      children: [
                        StarRatingDisplay(
                          rating: rating?.averageRating ?? 0.0,
                          totalRatings: rating?.totalRatings ?? 0,
                          size: 14,
                          showRatingText: true,
                          showRatingCount: true,
                        ),
                        // Debug info
                        if (rating?.error != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red[300],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '\$${(psychologist.hourlyRate ?? 0.0).toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Text(
                    '/hora',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
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
  final VoidCallback onStartChat;

  const _PsychologistDetailsModal({
    required this.psychologist,
    required this.scrollController,
    this.rating,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: psychologist.profilePictureUrl != null
                            ? NetworkImage(psychologist.profilePictureUrl!)
                            : null,
                        backgroundColor: AppConstants.lightAccentColor
                            .withOpacity(0.3),
                        child: psychologist.profilePictureUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              psychologist.fullName ?? 'Psicólogo sin nombre',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              psychologist.specialty ?? 'Especialidad general',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppConstants.lightAccentColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Rating detallado en el modal
                            Row(
                              children: [
                                StarRatingDisplay(
                                  rating: rating?.averageRating ?? 0.0,
                                  totalRatings: rating?.totalRatings ?? 0,
                                  size: 16,
                                  showRatingText: true,
                                  showRatingCount: true,
                                ),
                                if (rating?.error != null) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Error: ${rating!.error}',
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 16,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sobre el profesional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    psychologist.description ?? 'Descripción no disponible',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule,
                          title: 'Horarios',
                          subtitle:
                              psychologist.schedule != null &&
                                  psychologist.schedule!.isNotEmpty
                              ? psychologist.schedule!.entries
                                    .map((entry) {
                                      final day = entry.key;
                                      final scheduleForDay =
                                          entry.value as Map<String, dynamic>;
                                      final startTime =
                                          scheduleForDay['startTime'] ?? '';
                                      final endTime =
                                          scheduleForDay['endTime'] ?? '';
                                      return '$day: $startTime - $endTime';
                                    })
                                    .join('\n')
                              : 'Horario no definido',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.attach_money,
                          title: 'Precio',
                          subtitle:
                              '\$${(psychologist.hourlyRate ?? 0.0).toInt()}/hora',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlocProvider<AppointmentBloc>(
                                      create: (context) => AppointmentBloc(),
                                      child: AppointmentBookingScreen(
                                        psychologist: psychologist,
                                      ),
                                    ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppConstants.lightAccentColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Agendar Cita',
                            style: TextStyle(
                              color: AppConstants.lightAccentColor,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (psychologist.isAvailable ?? false)
                              ? onStartChat
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.lightAccentColor,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            (psychologist.isAvailable ?? false)
                                ? 'Iniciar Chat'
                                : 'No Disponible',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConstants.lightAccentColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
