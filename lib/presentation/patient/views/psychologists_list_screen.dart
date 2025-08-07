// lib/presentation/patient/views/psychologists_list_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/psychologist_chat_screen.dart';

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

  // Datos de ejemplo de psicólogos
  // TODO: Reemplazar con datos reales del backend/Firebase
  final List<PsychologistModel> _psychologists = [
    PsychologistModel.example(
      id: 'p1',
      username: 'Dra. María González',
      email: 'maria.gonzalez@example.com',
      specialty: 'Depresión',
      rating: 4.8,
      isAvailable: true,
      profilePictureUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      description:
          'Especialista en terapia cognitivo-conductual con 10 años de experiencia.',
      hourlyRate: 80.0,
      schedule: 'Lun-Vie 9:00-18:00',
      professionalTitle: 'Psicóloga Clínica',
      yearsExperience: 10,
      education: 'Maestría en Psicología Clínica - Universidad Nacional',
      certifications: 'Certificación en Terapia Cognitivo-Conductual',
    ),
    PsychologistModel.example(
      id: 'p2',
      username: 'Dr. Carlos Rodríguez',
      email: 'carlos.rodriguez@example.com',
      specialty: 'Ansiedad',
      rating: 4.9,
      isAvailable: true,
      profilePictureUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      description:
          'Psicólogo clínico especializado en trastornos de ansiedad y pánico.',
      hourlyRate: 75.0,
      schedule: 'Mar-Sáb 10:00-19:00',
    ),
    PsychologistModel.example(
      id: 'p3',
      username: 'Dra. Ana Martínez',
      email: 'ana.martinez@example.com',
      specialty: 'Terapia de Pareja',
      rating: 4.7,
      isAvailable: false,
      profilePictureUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
      description: 'Terapeuta familiar y de pareja con enfoque sistémico.',
      hourlyRate: 90.0,
      schedule: 'Lun-Jue 14:00-20:00',
    ),
    PsychologistModel.example(
      id: 'p4',
      username: 'Dr. Luis Herrera',
      email: 'luis.herrera@example.com',
      specialty: 'Adicciones',
      rating: 4.6,
      isAvailable: true,
      profilePictureUrl: 'https://randomuser.me/api/portraits/men/70.jpg',
      description:
          'Especialista en tratamiento de adicciones y rehabilitación.',
      hourlyRate: 85.0,
      schedule: 'Lun-Vie 8:00-16:00',
    ),
  ];

  List<PsychologistModel> get _filteredPsychologists {
    return _psychologists.where((psychologist) {
      final matchesSearch =
          psychologist.username.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (psychologist.specialty?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      final matchesSpecialty =
          _selectedSpecialty == 'Todas' ||
          psychologist.specialty == _selectedSpecialty;
      return matchesSearch && matchesSpecialty;
    }).toList();
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
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
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

          // Filtros de especialidad
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
                      setState(() {
                        _selectedSpecialty = specialty;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lista de psicólogos
          Expanded(
            child: _filteredPsychologists.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPsychologists.length,
                    itemBuilder: (context, index) {
                      final psychologist = _filteredPsychologists[index];
                      return _PsychologistCard(
                        psychologist: psychologist,
                        onTap: () => _onPsychologistSelected(psychologist),
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
    if (!psychologist.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${psychologist.username} no está disponible en este momento',
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
              onStartChat: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PsychologistChatScreen(
                      psychologistName: psychologist.username,
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
  final VoidCallback onTap;

  const _PsychologistCard({required this.psychologist, required this.onTap});

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
              // Foto de perfil
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

              // Información del psicólogo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psychologist.username,
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
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          (psychologist.rating ?? 0.0).toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: psychologist.isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            psychologist.isAvailable
                                ? 'Disponible'
                                : 'No disponible',
                            style: TextStyle(
                              fontSize: 10,
                              color: psychologist.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de precio
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
  final VoidCallback onStartChat;

  const _PsychologistDetailsModal({
    required this.psychologist,
    required this.scrollController,
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
          // Handle
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
                  // Header con foto y info básica
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
                              psychologist.username,
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${psychologist.rating ?? 0.0} (128 reseñas)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Descripción
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

                  // Horarios y precio
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule,
                          title: 'Horarios',
                          subtitle:
                              psychologist.schedule ?? 'Horario por definir',
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

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Agendar cita
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Funcionalidad de agendar cita próximamente',
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
                          onPressed: psychologist.isAvailable
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
                            psychologist.isAvailable
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
