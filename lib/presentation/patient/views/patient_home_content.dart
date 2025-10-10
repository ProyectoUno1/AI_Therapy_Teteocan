// lib/presentation/patient/views/patient_home_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_state.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/widgets/daily_exercise_carousel.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/article_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/article_detail_screen.dart';

class DailyTip {
  final String title;
  final String description;
  final IconData icon;

  const DailyTip({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class DailyTipsManager {
  static const List<DailyTip> _tips = [
    DailyTip(
      title: 'Practica la atención plena',
      description:
          'Dedica 5 minutos cada mañana a respirar conscientemente y observar tus pensamientos sin juzgarlos.',
      icon: Icons.self_improvement,
    ),
    DailyTip(
      title: 'Desconexión digital',
      description:
          'Toma un descanso de 30 minutos sin dispositivos para reconectar contigo mismo.',
      icon: Icons.phone_disabled,
    ),
    DailyTip(
      title: 'Diario de gratitud',
      description:
          'Escribe 3 cosas por las que te sientes agradecido hoy. La gratitud mejora tu bienestar.',
      icon: Icons.favorite,
    ),
    DailyTip(
      title: 'Ejercicio físico',
      description:
          'Camina al menos 15 minutos al aire libre. El ejercicio libera endorfinas naturales.',
      icon: Icons.directions_walk,
    ),
    DailyTip(
      title: 'Conexión social',
      description:
          'Llama o envía un mensaje a alguien importante para ti. Las conexiones nutren el alma.',
      icon: Icons.group,
    ),
    DailyTip(
      title: 'Momento de calma',
      description:
          'Encuentra 10 minutos de silencio completo para relajarte y recargar energías.',
      icon: Icons.spa,
    ),
    DailyTip(
      title: 'Aprendizaje nuevo',
      description:
          'Lee sobre algo que te interese durante 10 minutos. Mantén tu mente activa y curiosa.',
      icon: Icons.menu_book,
    ),
    DailyTip(
      title: 'Organiza tu espacio',
      description:
          'Dedica 15 minutos a organizar tu entorno. Un espacio limpio calma la mente.',
      icon: Icons.cleaning_services,
    ),
    DailyTip(
      title: 'Escucha música',
      description:
          'Escucha tu música favorita por 20 minutos. La música puede mejorar tu estado de ánimo.',
      icon: Icons.music_note,
    ),
    DailyTip(
      title: 'Ayuda a otros',
      description:
          'Realiza un pequeño acto de bondad hoy. Ayudar a otros también te ayuda a ti.',
      icon: Icons.volunteer_activism,
    ),
    DailyTip(
      title: 'Hidrátate bien',
      description:
          'Bebe al menos 8 vasos de agua hoy. La hidratación afecta tu energía y concentración.',
      icon: Icons.local_drink,
    ),
    DailyTip(
      title: 'Respiración profunda',
      description:
          'Practica 5 respiraciones profundas cuando te sientas estresado. Es tu calmante natural.',
      icon: Icons.air,
    ),
    DailyTip(
      title: 'Tiempo en la naturaleza',
      description:
          'Pasa al menos 20 minutos en contacto con la naturaleza. Reduce el estrés naturalmente.',
      icon: Icons.park,
    ),
    DailyTip(
      title: 'Sonríe más',
      description:
          'Sonríe intencionalmente 5 veces hoy. Incluso una sonrisa forzada puede mejorar tu humor.',
      icon: Icons.sentiment_very_satisfied,
    ),
  ];

  static List<DailyTip> getTipsForToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    List<DailyTip> todaysTips = [];
    for (int i = 0; i < 3; i++) {
      int index =
          (dayOfYear + i * 5) %
          _tips.length;
      todaysTips.add(_tips[index]);
    }

    return todaysTips;
  }

  static String getTodayMotivationalMessage() {
    final messages = [
      "¡Hoy es un nuevo día lleno de posibilidades!",
      "Cada pequeño paso cuenta en tu bienestar.",
      "Tu salud mental es una prioridad importante.",
      "Recuerda: está bien no estar bien todo el tiempo.",
      "Eres más fuerte de lo que crees.",
      "El autocuidado no es egoísmo, es necesario.",
      "Hoy es una oportunidad para cuidarte mejor.",
    ];

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return messages[dayOfYear % messages.length];
  }
}

class PatientHomeContent extends StatefulWidget { 
  final String patientId;

  const PatientHomeContent({super.key, required this.patientId});

  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  
  @override
void initState() {
  super.initState();
 
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ArticleBloc>().add(LoadPublishedArticles());
    _loadPatientAppointments();
  });
  
  _loadTodayEmotion();
}

  void _loadTodayEmotion() {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.read<EmotionBloc>().add(LoadTodayEmotion(currentUser.uid));
    }
  } catch (e) {
    print('Error loading today emotion: $e');
  }
}

  void _loadPatientAppointments() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        context.read<AppointmentBloc>().add(
          LoadAppointmentsEvent(
            userId: currentUser.uid,
            isForPsychologist: false,
            startDate: DateTime.now().subtract(const Duration(days: 1)), 
            endDate: DateTime.now().add(const Duration(days: 365)), 
          ),
        );
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  void _showTipDialog(BuildContext context, DailyTip tip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(tip.icon, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            tip.description,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EmotionBloc, EmotionState>(
          listener: (context, state) {
            if (!context.mounted) return; 

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
                  content: Text(' Emoción registrada correctamente'),
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
              'Mensaje del día',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Poppins',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Inspiración para hoy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      DailyTipsManager.getTodayMotivationalMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor.withOpacity(0.05),
                    AppConstants.primaryColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: BlocBuilder<EmotionBloc, EmotionState>(
                builder: (context, emotionState) {
                  return BlocBuilder<HomeContentCubit, HomeContentState>(
                    builder: (context, homeState) {
                      final todayEmotion = emotionState is EmotionLoaded
                          ? emotionState.todayEmotion
                          : null;
                      final hasEmotionToday = todayEmotion != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: AppConstants.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Cómo te sientes hoy?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'Poppins',
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'Tu bienestar emocional es importante',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasEmotionToday) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Registrado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (emotionState is EmotionLoading) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ImprovedFeelingIcon(
                                    emoji: '😢',
                                    label: 'Terrible',
                                    feeling: Feeling.terrible,
                                    isSelected: homeState.selectedFeeling == Feeling.terrible,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday
                                        ? null
                                        : () => context
                                              .read<HomeContentCubit>()
                                              .selectFeeling(Feeling.terrible),
                                  ),
                                  _ImprovedFeelingIcon(
                                    emoji: '😔',
                                    label: 'Mal',
                                    feeling: Feeling.bad,
                                    isSelected: homeState.selectedFeeling == Feeling.bad,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday
                                        ? null
                                        : () => context
                                              .read<HomeContentCubit>()
                                              .selectFeeling(Feeling.bad),
                                  ),
                                  _ImprovedFeelingIcon(
                                    emoji: '😐',
                                    label: 'Regular',
                                    feeling: Feeling.neutral,
                                    isSelected: homeState.selectedFeeling == Feeling.neutral,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday
                                        ? null
                                        : () => context
                                              .read<HomeContentCubit>()
                                              .selectFeeling(Feeling.neutral),
                                  ),
                                  _ImprovedFeelingIcon(
                                    emoji: '😊',
                                    label: 'Bien',
                                    feeling: Feeling.good,
                                    isSelected: homeState.selectedFeeling == Feeling.good,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday
                                        ? null
                                        : () => context
                                              .read<HomeContentCubit>()
                                              .selectFeeling(Feeling.good),
                                  ),
                                  _ImprovedFeelingIcon(
                                    emoji: '😄',
                                    label: 'Genial',
                                    feeling: Feeling.great,
                                    isSelected: homeState.selectedFeeling == Feeling.great,
                                    isDisabled: hasEmotionToday,
                                    onTap: hasEmotionToday
                                        ? null
                                        : () => context
                                              .read<HomeContentCubit>()
                                              .selectFeeling(Feeling.great),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (hasEmotionToday) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_emotions,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
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
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[600],
                                    size: 20,
                                  ),
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
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Consejos diarios',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: DailyTipsManager.getTipsForToday().length,
                itemBuilder: (context, index) {
                  final tip = DailyTipsManager.getTipsForToday()[index];
                  return _TipCard(
                    title: tip.title,
                    description: tip.description,
                    icon: tip.icon,
                    onTap: () {
                      _showTipDialog(context, tip);
                    },
                  );
                },
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
                // Mostrar loading si está cargando
                if (state.isLoadingState) {
                  return _buildAppointmentLoading();
                }
                
                // Mostrar error si hay problema
                if (state.isError) {
                  return _buildAppointmentError(state.errorMessage);
                }
                
                // Filtrar solo citas futuras confirmadas
                final upcomingAppointments = state.upcomingAppointments
                    .where((appointment) => 
                        appointment.status == AppointmentStatus.confirmed ||
                        appointment.status == AppointmentStatus.in_progress)
                    .toList();
                
                if (upcomingAppointments.isNotEmpty) {
                  final upcomingAppointment = upcomingAppointments.first;
                  return _AppointmentCard(appointment: upcomingAppointment);
                } else {
                  return _buildNoAppointmentsCard();
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
            BlocBuilder<ArticleBloc, ArticleState>(
              builder: (context, state) {
                if (state is ArticlesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ArticlesLoaded) {
                  if (state.articles.isEmpty) {
                    final exampleArticle = Article(
                      id: '1',
                      title: 'Bienvenido a tu camino de bienestar',
                      content:
                          'Este es un artículo de ejemplo para guiarte en tu viaje hacia el bienestar mental. Aquí encontrarás recursos, consejos y guías que te ayudarán a comprender y gestionar tus emociones.',
                      summary:
                          'Un artículo de ejemplo sobre el bienestar mental.',
                      psychologistId: 'psicologo_ejemplo',
                      fullName: 'Equipo AI Therapy',
                      imageUrl:
                          'https://images.pexels.com/photos/4101143/pexels-photo-4101143.jpeg',
                      isPublished: true,
                      publishedAt: DateTime.now(),
                      readingTimeMinutes: 5,
                      tags: ['bienestar', 'ejemplo', 'salud_mental'],
                      category: 'Bienestar',
                      createdAt: DateTime(2025),
                    );
                    return _ArticleCarousel(
                      articles: [exampleArticle],
                      patientId: widget.patientId,
                    );
                  }
                  return _ArticleCarousel(
                    articles: state.articles,
                    patientId: widget.patientId,
                  );
                } else if (state is ArticlesError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

   Widget _buildAppointmentLoading() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Cargando citas...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar error de citas
  Widget _buildAppointmentError(String? errorMessage) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'Error al cargar citas',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPatientAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cuando no hay citas
  Widget _buildNoAppointmentsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes citas próximas',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Agenda una cita con tu psicólogo',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _feelingToText(Feeling feeling) {
    switch (feeling) {
      case Feeling.terrible:
        return 'Terrible';
      case Feeling.bad:
        return 'Mal';
      case Feeling.neutral:
        return 'Regular';
      case Feeling.good:
        return 'Bien';
      case Feeling.great:
        return 'Genial';
      default:
        return 'No especificado';
    }
  }
}

// Nuevo carrusel de artículos
class _ArticleCarousel extends StatefulWidget {
  final List<Article> articles;
  final String patientId;

  const _ArticleCarousel({
    required this.articles,
    required this.patientId,
  });

  @override
  State<_ArticleCarousel> createState() => _ArticleCarouselState();
}

class _ArticleCarouselState extends State<_ArticleCarousel> {
  PageController? _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    // Retrasamos el inicio del timer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDisposed && widget.articles.length > 1) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _timer?.cancel();
      _pageController?.dispose();
      _isDisposed = true;
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      if (_pageController != null && mounted) {
        try {
          if (_currentPage < widget.articles.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }

          if (_pageController!.hasClients) {
            _pageController!.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        } catch (e) {
          timer.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.articles.length,
            itemBuilder: (context, index) {
              final article = widget.articles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _ArticleCarouselCard(
                  article: article,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          article: article,
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicadores de página
        if (widget.articles.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.articles.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppConstants.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Tarjeta de artículo para el carrusel
class _ArticleCarouselCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleCarouselCard({
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = 'Fecha no disponible';
    final dateToShow = article.publishedAt ?? article.createdAt ?? article.updatedAt;
    
    if (dateToShow != null) {
      formattedDate = '${dateToShow.day}/${dateToShow.month}/${dateToShow.year}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del artículo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                article.imageUrl ?? '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.article, color: Colors.grey, size: 50),
                    ),
                  );
                },
              ),
            ),
            
            // Contenido de la tarjeta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Resumen
                    if (article.summary != null && article.summary!.isNotEmpty)
                      Text(
                        article.summary!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // Información del artículo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Autor
                        Expanded(
                          child: Text(
                            'Por ${article.fullName ?? 'Autor'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: AppConstants.lightAccentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Tiempo de lectura
                        Row(
                          children: [
                            Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${article.readingTimeMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Fecha
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImprovedFeelingIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final Feeling feeling;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ImprovedFeelingIcon({
    required this.emoji,
    required this.label,
    required this.feeling,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppConstants.primaryColor
                    : Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 170,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppConstants.primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}