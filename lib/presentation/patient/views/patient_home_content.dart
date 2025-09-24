// lib/presentation/patient/views/patient_home_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_state.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/widgets/daily_exercise_carousel.dart';

class Article {
  final String title;
  final String author;
  final String imageUrl;
  final String date;

  Article({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.date,
  });
}

class PatientHomeContent extends StatelessWidget {
  final String patientId;

  const PatientHomeContent({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final List<Article> articles = [
      Article(
        title: 'Cómo afrontar el estrés: estrategias prácticas',
        author: 'Dr. Alex Rodriguez',
        imageUrl: 'https://img.freepik.com/free-photo/mental-health-care-concept-mind-hand-holding-brain_23-2151042571.jpg',
        date: 'Julio 15, 2025',
      ),
      Article(
        title: 'El poder de la atención plena en la vida diaria',
        author: 'Dr. Maria Lopez',
        imageUrl: 'https://img.freepik.com/free-photo/happy-young-woman-doing-yoga-outdoors-sunrise-canyon_1150-13783.jpg',
        date: 'Julio 10, 2025',
      ),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<EmotionBloc, EmotionState>(
          listener: (context, state) {
            if (state is EmotionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is EmotionSavedSuccessfully) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Emoción registrada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frase del día',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '"El autocuidado es la forma de recuperar tu poder."\n\n— Lalah Delia',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sección de ejercicios diarios agregada
            const Text(
              'Ejercicios diarios',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            DailyExerciseCarousel(),
            const SizedBox(height: 24),

            const Text(
              '¿Cómo te sientes?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            BlocBuilder<EmotionBloc, EmotionState>(
              builder: (context, emotionState) {
                return BlocBuilder<HomeContentCubit, HomeContentState>(
                  builder: (context, homeState) {
                    // Determinar si ya hay una emoción registrada hoy
                    final todayEmotion = emotionState is EmotionLoaded ? emotionState.todayEmotion : null;
                    final hasEmotionToday = todayEmotion != null;
                    
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('¿Cómo te sientes hoy?', 
                                    style: TextStyle(fontFamily: 'Poppins')),
                                if (hasEmotionToday) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.check_circle, 
                                      color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Registrado',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontFamily: 'Poppins'
                                      )),
                                ]
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (emotionState is EmotionLoading) ...[
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _FeelingIcon(
                                    icon: Icons.thumb_down_alt_outlined,
                                    label: 'Terrible',
                                    isSelected: homeState.selectedFeeling == Feeling.terrible,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday 
                                        ? null 
                                        : () => context.read<HomeContentCubit>().selectFeeling(Feeling.terrible),
                                  ),
                                  _FeelingIcon(
                                    icon: Icons.sentiment_dissatisfied,
                                    label: 'Mal',
                                    isSelected: homeState.selectedFeeling == Feeling.bad,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday 
                                        ? null 
                                        : () => context.read<HomeContentCubit>().selectFeeling(Feeling.bad),
                                  ),
                                  _FeelingIcon(
                                    icon: Icons.sentiment_neutral,
                                    label: 'Regular',
                                    isSelected: homeState.selectedFeeling == Feeling.neutral,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday 
                                        ? null 
                                        : () => context.read<HomeContentCubit>().selectFeeling(Feeling.neutral),
                                  ),
                                  _FeelingIcon(
                                    icon: Icons.sentiment_satisfied,
                                    label: 'Bien',
                                    isSelected: homeState.selectedFeeling == Feeling.good,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday 
                                        ? null 
                                        : () => context.read<HomeContentCubit>().selectFeeling(Feeling.good),
                                  ),
                                  _FeelingIcon(
                                    icon: Icons.thumb_up_alt_outlined,
                                    label: 'Genial',
                                    isSelected: homeState.selectedFeeling == Feeling.great,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday 
                                        ? null 
                                        : () => context.read<HomeContentCubit>().selectFeeling(Feeling.great),
                                  ),
                                ],
                              ),
                            ],
                            
                            if (hasEmotionToday) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.emoji_emotions, 
                                        color: Colors.green[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Hoy te sientes: ${_feelingToText(todayEmotion!.feeling)}',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (emotionState is EmotionError) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                        color: Colors.red[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error al cargar emociones',
                                        style: TextStyle(
                                          color: Colors.red[800],
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Ejercicio rápido',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
                  child: const Icon(Icons.spa, color: AppConstants.lightAccentColor),
                ),
                title: const Text('Respiración profunda', style: TextStyle(fontFamily: 'Poppins')),
                subtitle: const Text('3 min', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  // TODO: Navegar a la pantalla de ejercicios de respiración.
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Tips de Psicología Semanales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _TipCard(
                    title: 'Practica la atención plena',
                    onTap: () {
                      // TODO: Navegar a la pantalla de tips o de un tip específico.
                    },
                  ),
                  _TipCard(
                    title: 'Desconexión digital',
                    onTap: () {
                      // TODO: Navegar a la pantalla de tips o de un tip específico.
                    },
                  ),
                  _TipCard(
                    title: 'Diario de gratitud',
                    onTap: () {
                      // TODO: Navegar a la pantalla de tips o de un tip específico.
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Próxima cita',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                if (state.upcomingAppointments.isNotEmpty) {
                  final upcomingAppointment = state.upcomingAppointments.first;
                  
                  return _AppointmentCard(appointment: upcomingAppointment);
                } else {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No tienes citas próximas.',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Artículos de psicólogos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return _ArticleCard(
                  article: article,
                  onTap: () {
                    // TODO: Navegar a la pantalla de detalle del artículo.
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _feelingToText(Feeling feeling) {
    switch (feeling) {
      case Feeling.terrible: return 'Terrible';
      case Feeling.bad: return 'Mal';
      case Feeling.neutral: return 'Regular';
      case Feeling.good: return 'Bien';
      case Feeling.great: return 'Genial';
      default: return 'No especificado';
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.psychologistName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.psychologistSpecialty,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${appointment.scheduledDateTime.day}/${appointment.scheduledDateTime.month}/${appointment.scheduledDateTime.year}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${appointment.scheduledDateTime.hour}:${appointment.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _FeelingIcon({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDisabled 
        ? Colors.grey[300] 
        : (isSelected ? AppConstants.lightAccentColor : Colors.grey);
        
    final backgroundColor = isDisabled 
        ? Colors.grey[100] 
        : (isSelected ? AppConstants.lightAccentColor.withOpacity(0.15) : Colors.grey[200]);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: backgroundColor,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: color, 
              fontSize: 12, 
              fontFamily: 'Poppins',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _TipCard({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.lightAccentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(title, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const _ArticleCard({required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By ${article.author}',
                        style: const TextStyle(
                          color: AppConstants.lightAccentColor,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        article.date,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
      ),
    );
  }
}