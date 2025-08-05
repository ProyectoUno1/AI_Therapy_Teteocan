// lib/presentation/patient/views/psychologists_list_screen_tab.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/psychologist_chat_screen.dart';

class PsychologistsListScreenTab extends StatefulWidget {
  const PsychologistsListScreenTab({super.key});

  @override
  State<PsychologistsListScreenTab> createState() =>
      _PsychologistsListScreenTabState();
}

class _PsychologistsListScreenTabState
    extends State<PsychologistsListScreenTab> {
  String _searchQuery = '';
  String _selectedSpecialty = 'Todas';

  // Datos mock de psicólogos
  final List<PsychologistModel> _mockPsychologists = [
    PsychologistModel.example(
      id: '1',
      username: 'Dr. María González',
      email: 'maria@example.com',
      specialty: 'Ansiedad y Depresión',
      rating: 4.8,
      isAvailable: true,
      description:
          'Especialista en terapia cognitivo-conductual con más de 10 años de experiencia. Ayudo a pacientes con ansiedad, depresión y trastornos del estado de ánimo.',
      hourlyRate: 80.0,
      schedule: 'Lun-Vie 9:00-18:00',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400',
    ),
    PsychologistModel.example(
      id: '2',
      username: 'Dr. Carlos Mendoza',
      email: 'carlos@example.com',
      specialty: 'Terapia de Pareja',
      rating: 4.6,
      isAvailable: true,
      description:
          'Terapeuta especializado en relaciones de pareja y familiares. Enfoque sistémico y humanista para resolver conflictos.',
      hourlyRate: 90.0,
      schedule: 'Mar-Sab 10:00-20:00',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400',
    ),
    PsychologistModel.example(
      id: '3',
      username: 'Dra. Ana Ramírez',
      email: 'ana@example.com',
      specialty: 'Psicología Infantil',
      rating: 4.9,
      isAvailable: false,
      description:
          'Especialista en psicología infantil y adolescente. Trabajo con trastornos del desarrollo, TDAH y problemas de conducta.',
      hourlyRate: 75.0,
      schedule: 'Lun-Jue 8:00-16:00',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1594824475068-7c0bd2ac9058?w=400',
    ),
    PsychologistModel.example(
      id: '4',
      username: 'Dr. Luis Torres',
      email: 'luis@example.com',
      specialty: 'Adicciones',
      rating: 4.7,
      isAvailable: true,
      description:
          'Especialista en tratamiento de adicciones y trastornos de conducta. Enfoque integral y personalizado.',
      hourlyRate: 85.0,
      schedule: 'Lun-Vie 14:00-22:00',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400',
    ),
  ];

  List<PsychologistModel> get _filteredPsychologists {
    return _mockPsychologists.where((psychologist) {
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
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header con título y barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Psicólogos Disponibles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
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
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.black),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Lista de psicólogos
          Expanded(
            child: _filteredPsychologists.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                'Especialidad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    [
                      'Todas',
                      'Ansiedad y Depresión',
                      'Terapia de Pareja',
                      'Psicología Infantil',
                      'Adicciones',
                    ].map((specialty) {
                      return FilterChip(
                        label: Text(specialty),
                        selected: _selectedSpecialty == specialty,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSpecialty = specialty;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.lightAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      color: Colors.white,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto del psicólogo
              CircleAvatar(
                radius: 30,
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
                backgroundImage: psychologist.profilePictureUrl != null
                    ? NetworkImage(psychologist.profilePictureUrl!)
                    : null,
                child: psychologist.profilePictureUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: AppConstants.lightAccentColor,
                      )
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
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      psychologist.specialty ?? 'Especialidad general',
                      style: const TextStyle(
                        color: AppConstants.lightAccentColor,
                        fontSize: 14,
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
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
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
                        backgroundColor: AppConstants.lightAccentColor
                            .withOpacity(0.2),
                        backgroundImage: psychologist.profilePictureUrl != null
                            ? NetworkImage(psychologist.profilePictureUrl!)
                            : null,
                        child: psychologist.profilePictureUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: AppConstants.lightAccentColor,
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
                                fontSize: 22,
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
                                  size: 16,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${psychologist.rating ?? 0.0} (128 reseñas)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
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
                    'Acerca de',
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

                  // Información adicional
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.lightAccentColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }
}
