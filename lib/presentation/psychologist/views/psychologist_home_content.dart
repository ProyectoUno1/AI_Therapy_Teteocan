//lib/presentation/psychologist/views/psychologist_home_content.dart
//vista del psicologo

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

class PsychologistPatient {
  final String id;
  final String name;
  final String? imageUrl;
  final String latestMessage;
  final String lastSeen;
  final bool isOnline;

  const PsychologistPatient({
    required this.id,
    required this.name,
    this.imageUrl,
    this.latestMessage = '',
    this.lastSeen = '',
    this.isOnline = false,
  });
}

class Session {
  final String id;
  final DateTime time;
  final PsychologistPatient patient;
  final String type;
  final int durationMinutes;

  Session({
    required this.id,
    required this.time,
    required this.patient,
    required this.type,
    required this.durationMinutes,
  });
}

class PsychologistArticleSummary {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime date;

  PsychologistArticleSummary({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
  });
}

class PsychologistHomeContent extends StatelessWidget {
  const PsychologistHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Session> todaySessions = [
      Session(
        id: 's1',
        time: DateTime(2025, 7, 25, 9, 30),
        patient: const PsychologistPatient(
          id: 'p1',
          name: 'Mario',
          imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
          latestMessage: '',
          lastSeen: '',
        ),
        type: 'Sesión de terapia',
        durationMinutes: 60,
      ),
      Session(
        id: 's2',
        time: DateTime(2025, 7, 25, 11, 0),
        patient: const PsychologistPatient(
          id: 'p2',
          name: 'Maria',
          imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
          latestMessage: '',
          lastSeen: '',
        ),
        type: 'Consulta inicial',
        durationMinutes: 45,
      ),
      Session(
        id: 's3',
        time: DateTime(2025, 7, 25, 14, 15),
        patient: const PsychologistPatient(
          id: 'p3',
          name: 'David',
          imageUrl: 'https://randomuser.me/api/portraits/men/70.jpg',
          latestMessage: '',
          lastSeen: '',
        ),
        type: 'Consulta inicial',
        durationMinutes: 60,
      ),
    ];

    final List<PsychologistPatient> recentChats = [
      const PsychologistPatient(
        id: 'p1',
        name: 'Mario',
        imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        latestMessage: 'Gracias por la sesión de hoy. Tengo..',
        lastSeen: '01:45 a.m.',
        isOnline: true,
      ),
      const PsychologistPatient(
        id: 'p2',
        name: 'Maria',
        imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        latestMessage: '¡Esperamos con ansias nuestra sesión de mañana!',
        lastSeen: '12:30 p.m.',
        isOnline: false,
      ),
      const PsychologistPatient(
        id: 'p4',
        name: 'Jaime',
        imageUrl: 'https://randomuser.me/api/portraits/men/6.jpg',
        latestMessage: "He estado practicando la técnica de atención plena...",
        lastSeen: '09:15 a.m.',
        isOnline: false,
      ),
    ];

    final List<Session> recentNotesAndSessions = [
      Session(
        id: 's1',
        time: DateTime(2025, 7, 17),
        patient: const PsychologistPatient(
          id: 'p1',
          name: 'Mario',
          imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
          latestMessage: '',
          lastSeen: '',
        ),
        type: 'Sesión de terapia',
        durationMinutes: 60,
      ),
      Session(
        id: 's2',
        time: DateTime(2025, 7, 10),
        patient: const PsychologistPatient(
          id: 'p2',
          name: 'Maria',
          imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
          latestMessage: '',
          lastSeen: '',
        ),
        type: 'Consulta inicial',
        durationMinutes: 45,
      ),
    ];

    final List<PsychologistArticleSummary> yourArticles = [
      PsychologistArticleSummary(
        id: 'a1',
        title: 'Comprender los desencadenantes de la ansiedad',
        imageUrl: 'https://picsum.photos/seed/psychologist_article1/300/200',
        date: DateTime(2025, 7, 20),
      ),
      PsychologistArticleSummary(
        id: 'a2',
        title: 'El poder de la terapia cognitivo-conductual',
        imageUrl: 'https://picsum.photos/seed/psychologist_article2/300/200',
        date: DateTime(2025, 7, 15),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary Section
          _buildSectionHeader(
            context,
            'Resumen de hoy',
            suffixWidget: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppConstants.secondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '7 sesiones esta semana',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.secondaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...todaySessions
              .map((session) => _SessionCard(session: session))
              .toList(),
          const SizedBox(height: 24),

          // Your Schedule Section
          _buildSectionHeader(
            context,
            'Tu horario',
            suffixWidget: CircleAvatar(
              backgroundColor: AppConstants.secondaryColor,
              radius: 16,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () {
                  /* Add schedule logic */
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(const Size(32, 32)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ScheduleToggleButton(
                        label: 'Dia',
                        isSelected: false,
                        onTap: () {},
                      ),
                      _ScheduleToggleButton(
                        label: 'Semana',
                        isSelected: true,
                        onTap: () {},
                      ), // 'Week' is selected in image
                      _ScheduleToggleButton(
                        label: 'Mes',
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.arrow_left, color: Colors.grey[600]),
                      Text(
                        'Julio 2025',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.grey[600]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: 31, // For July
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isCurrentDay =
                          (day == DateTime.now().day &&
                          DateTime.now().month == 7 &&
                          DateTime.now().year == 2025);
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentDay
                              ? AppConstants.secondaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isCurrentDay
                                ? AppConstants.secondaryColor
                                : Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Chats Section
          _buildSectionHeader(
            context,
            'Chats recientes',
            suffixText: 'Ver todos',
            onTapSuffix: () {
              /* Navigate to chats */
            },
          ),
          const SizedBox(height: 8),
          ...recentChats
              .map((patient) => _ChatSummaryCard(patient: patient))
              .toList(),
          const SizedBox(height: 24),

          // Recent Notes and Sessions Section
          _buildSectionHeader(
            context,
            'Notas y sesiones recientes',
            suffixText: 'Ver todas',
            onTapSuffix: () {
              /* Navigate to notes/sessions */
            },
          ),
          const SizedBox(height: 8),
          ...recentNotesAndSessions
              .map((session) => _NoteSessionCard(session: session))
              .toList(),
          const SizedBox(height: 24),

          // Availability Section
          _buildSectionHeader(context, 'Disponibilidad'),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Disponible para sesiones',
                        style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                      ),
                      Switch(
                        value: true,
                        onChanged: (bool value) {},
                        activeColor: AppConstants.secondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        /* Enable vacation mode */
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.secondaryColor,
                        side: const BorderSide(
                          color: AppConstants.secondaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Habilitar modo vacaciones',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Usage Insights'),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const _InsightMetric(
                        value: '18',
                        label: 'Pacientes activos',
                      ),
                      const _InsightMetric(
                        value: '42',
                        label: 'Sesiones este mes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Porcentaje de ocupación',
                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                      ),
                      const Spacer(),
                      const Text(
                        '48%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.48, // 48%
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppConstants.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '20 ocupado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '22 disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            'Tus artículos',
            suffixWidget: CircleAvatar(
              backgroundColor: AppConstants.secondaryColor,
              radius: 16,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () {
                  // Obtén el ID del usuario actual
                  final String? currentUserId =
                      FirebaseAuth.instance.currentUser?.uid;

                  // Verifica si el ID existe antes de navegar
                  if (currentUserId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Crear Nuevo Artículo'),
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            iconTheme: Theme.of(
                              context,
                            ).iconTheme.copyWith(size: 24),
                            elevation: 0,
                            centerTitle: true,
                          ),
                          body: Center(
                            child: Text(
                              'Aquí puedes crear un nuevo artículo, Psicólogo ID: $currentUserId',
                              style: const TextStyle(fontFamily: 'Poppins'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Muestra un mensaje de error si el usuario no está autenticado
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Error: No se pudo obtener el ID del usuario. Por favor, vuelva a iniciar sesión.',
                        ),
                      ),
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(const Size(32, 32)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: yourArticles.length,
              itemBuilder: (context, index) {
                final article = yourArticles[index];
                return _PsychologistArticleCard(article: article);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? suffixText,
    VoidCallback? onTapSuffix,
    Widget? suffixWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          if (suffixText != null)
            GestureDetector(
              onTap: onTapSuffix,
              child: Text(
                suffixText,
                style: const TextStyle(
                  color: AppConstants.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          if (suffixWidget != null) suffixWidget,
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;

  const _SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(session.time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 20,
              backgroundImage: session.patient.imageUrl != null
                  ? NetworkImage(session.patient.imageUrl!)
                  : null,
              child: session.patient.imageUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.patient.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    session.type,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${session.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.secondaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleToggleButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppConstants.secondaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _ChatSummaryCard extends StatelessWidget {
  final PsychologistPatient patient;

  const _ChatSummaryCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.transparent,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: patient.imageUrl != null
                  ? NetworkImage(patient.imageUrl!)
                  : null,
              child: patient.imageUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.5),
            ),
            if (patient.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          patient.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          patient.latestMessage,
          style: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          patient.lastSeen,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontFamily: 'Poppins',
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class _NoteSessionCard extends StatelessWidget {
  final Session session;

  const _NoteSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: session.patient.imageUrl != null
                      ? NetworkImage(session.patient.imageUrl!)
                      : null,
                  child: session.patient.imageUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(
                    0.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        session.type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(session.time), // e.g., "17 Jul"
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${session.patient.name} Demostró un progreso significativo con las técnicas de manejo de la ansiedad. Continuar...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  final String value;
  final String label;

  const _InsightMetric({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.secondaryColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PsychologistArticleCard extends StatelessWidget {
  final PsychologistArticleSummary article;

  const _PsychologistArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              article.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(article.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
