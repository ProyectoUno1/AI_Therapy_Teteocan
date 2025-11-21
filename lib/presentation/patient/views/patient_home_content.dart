// lib/presentation/patient/views/patient_home_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

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
      description: 'Dedica 5 minutos cada mañana a respirar conscientemente y observar tus pensamientos sin juzgarlos.',
      icon: Icons.self_improvement,
    ),
    DailyTip(
      title: 'Desconexión digital',
      description: 'Toma un descanso de 30 minutos sin dispositivos para reconectar contigo mismo.',
      icon: Icons.phone_disabled,
    ),
    DailyTip(
      title: 'Diario de gratitud',
      description: 'Escribe 3 cosas por las que te sientes agradecido hoy. La gratitud mejora tu bienestar.',
      icon: Icons.favorite,
    ),
    DailyTip(
      title: 'Ejercicio físico',
      description: 'Camina al menos 15 minutos al aire libre. El ejercicio libera endorfinas naturales.',
      icon: Icons.directions_walk,
    ),
    DailyTip(
      title: 'Conexión social',
      description: 'Llama o envía un mensaje a alguien importante para ti. Las conexiones nutren el alma.',
      icon: Icons.group,
    ),
    DailyTip(
      title: 'Momento de calma',
      description: 'Encuentra 10 minutos de silencio completo para relajarte y recargar energías.',
      icon: Icons.spa,
    ),
    DailyTip(
      title: 'Aprendizaje nuevo',
      description: 'Lee sobre algo que te interese durante 10 minutos. Mantén tu mente activa y curiosa.',
      icon: Icons.menu_book,
    ),
    DailyTip(
      title: 'Organiza tu espacio',
      description: 'Dedica 15 minutos a organizar tu entorno. Un espacio limpio calma la mente.',
      icon: Icons.cleaning_services,
    ),
    DailyTip(
      title: 'Escucha música',
      description: 'Escucha tu música favorita por 20 minutos. La música puede mejorar tu estado de ánimo.',
      icon: Icons.music_note,
    ),
    DailyTip(
      title: 'Ayuda a otros',
      description: 'Realiza un pequeño acto de bondad hoy. Ayudar a otros también te ayuda a ti.',
      icon: Icons.volunteer_activism,
    ),
    DailyTip(
      title: 'Hidrátate bien',
      description: 'Bebe al menos 8 vasos de agua hoy. La hidratación afecta tu energía y concentración.',
      icon: Icons.local_drink,
    ),
    DailyTip(
      title: 'Respiración profunda',
      description: 'Practica 5 respiraciones profundas cuando te sientas estresado. Es tu calmante natural.',
      icon: Icons.air,
    ),
    DailyTip(
      title: 'Tiempo en la naturaleza',
      description: 'Pasa al menos 20 minutos en contacto con la naturaleza. Reduce el estrés naturalmente.',
      icon: Icons.park,
    ),
    DailyTip(
      title: 'Sonríe más',
      description: 'Sonríe intencionalmente 5 veces hoy. Incluso una sonrisa forzada puede mejorar tu humor.',
      icon: Icons.sentiment_very_satisfied,
    ),
  ];

  static List<DailyTip> getTipsForToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    List<DailyTip> todaysTips = [];
    for (int i = 0; i < 3; i++) {
      int index = (dayOfYear + i * 5) % _tips.length;
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
      _loadTodayEmotion();
    });
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
      builder: (BuildContext dialogContext) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _getConstrainedTextScaleFactor(context),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  tip.icon,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              tip.description,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Entendido',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ENVOLVER TODO EN MediaQuery PARA LIMITAR EL TEXT SCALE FACTOR
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;
          final bool isVeryWideScreen = constraints.maxWidth > 1200;
          
          return OrientationBuilder(
            builder: (context, orientation) {
              final bool isLandscape = orientation == Orientation.landscape;
              
              return MultiBlocListener(
                listeners: [
                  BlocListener<EmotionBloc, EmotionState>(
                    listener: (context, state) {
                      if (!context.mounted) return; 

                      if (state is EmotionError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error: ${state.message}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[700],
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (state is EmotionSavedSuccessfully) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text(
                                  '¡Emoción registrada correctamente!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[700],
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
                child: SingleChildScrollView(
                  padding: _getAdaptivePadding(constraints),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isVeryWideScreen ? 1400 : (isWideScreen ? 1200 : double.infinity),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MENSAJE DEL DÍA
                          _buildSectionTitle('Mensaje del día', constraints),
                          const SizedBox(height: 12),
                          _buildMotivationalCard(constraints),
                          const SizedBox(height: 24),
                          
                          // EJERCICIOS DIARIOS
                          _buildSectionTitle('Ejercicios diarios', constraints),
                          const SizedBox(height: 12),
                          DailyExerciseCarousel(),
                          const SizedBox(height: 24),
                          
                          // SECCIÓN DE EMOCIONES
                          _buildEmotionSection(context, constraints),
                          const SizedBox(height: 24),

                          // CONSEJOS DIARIOS
                          _buildSectionTitle('Consejos diarios', constraints),
                          const SizedBox(height: 12),
                          _buildAdaptiveTipsLayout(constraints, isLandscape),
                          const SizedBox(height: 24),

                          // PRÓXIMA CITA
                          _buildSectionTitle('Próxima cita', constraints),
                          const SizedBox(height: 12),
                          _buildAppointmentSection(context, constraints),
                          const SizedBox(height: 24),

                          // ARTÍCULOS
                          _buildSectionTitle('Artículos de psicólogos', constraints),
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
                                    content: 'Este es un artículo de ejemplo para guiarte en tu viaje hacia el bienestar mental.',
                                    summary: 'Un artículo de ejemplo sobre el bienestar mental.',
                                    psychologistId: 'psicologo_ejemplo',
                                    fullName: 'Equipo AI Therapy',
                                    imageUrl: 'https://images.pexels.com/photos/4101143/pexels-photo-4101143.jpeg',
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
                                    constraints: constraints,
                                  );
                                }
                                return _ArticleCarousel(
                                  articles: state.articles,
                                  patientId: widget.patientId,
                                  constraints: constraints,
                                );
                              } else if (state is ArticlesError) {
                                return Center(child: Text('Error: ${state.message}'));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          SizedBox(height: _getBottomSpacing(constraints)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  EdgeInsets _getAdaptivePadding(BoxConstraints constraints) {
    final double width = constraints.maxWidth;
    if (width > 1200) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 24);
    } else if (width > 800) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 20);
    } else if (width > 600) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  double _getBottomSpacing(BoxConstraints constraints) {
    return constraints.maxWidth > 600 ? 32.0 : 24.0;
  }

  Widget _buildSectionTitle(String title, BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    return Text(
      title,
      style: TextStyle(
        fontSize: isWide ? 20.0 : 18.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildMotivationalCard(BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: isWide 
            ? const EdgeInsets.all(20.0)
            : const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.wb_sunny,
              color: AppConstants.primaryColor,
              size: isWide ? 28.0 : 24.0,
            ),
            SizedBox(width: isWide ? 16.0 : 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspiración para hoy',
                    style: TextStyle(
                      fontSize: isWide ? 18.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DailyTipsManager.getTodayMotivationalMessage(),
                    style: TextStyle(
                      fontSize: isWide ? 16.0 : 14.0,
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

  Widget _buildEmotionSection(BuildContext context, BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    
    return Container(
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
      padding: isWide 
          ? const EdgeInsets.all(24.0)
          : const EdgeInsets.all(16.0),
      child: BlocBuilder<EmotionBloc, EmotionState>(
        builder: (context, emotionState) {
          return BlocBuilder<HomeContentCubit, HomeContentState>(
            builder: (context, homeState) {
              final todayEmotion = emotionState is EmotionLoaded
                  ? emotionState.todayEmotion
                  : null;
              final hasEmotionToday = todayEmotion != null;
              final isSaving = emotionState is EmotionSaving;

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
                          size: isWide ? 28.0 : 24.0,
                        ),
                      ),
                      SizedBox(width: isWide ? 20.0 : 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Cómo te sientes hoy?',
                              style: TextStyle(
                                fontSize: isWide ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              hasEmotionToday 
                                  ? 'Ya registraste tu emoción hoy'
                                  : 'Selecciona cómo te sientes',
                              style: TextStyle(
                                fontSize: isWide ? 14.0 : 13.0,
                                color: Colors.grey.shade600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSaving) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ] else if (hasEmotionToday) ...[
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: isWide ? 24.0 : 20.0,
                        ),
                        SizedBox(width: isWide ? 12.0 : 8.0),
                        Text(
                          'Registrado',
                          style: TextStyle(
                            fontSize: isWide ? 14.0 : 12.0,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (emotionState is EmotionLoading && !isSaving) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else ...[
                    _buildAdaptiveEmotionSelector(
                      context, 
                      homeState, 
                      hasEmotionToday || isSaving,
                      constraints
                    ),
                  ],

                  if (hasEmotionToday) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: isWide 
                          ? const EdgeInsets.all(20.0)
                          : const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green[50]!,
                            Colors.green[100]!.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.emoji_emotions,
                              color: Colors.green[700],
                              size: isWide ? 24.0 : 20.0,
                            ),
                          ),
                          SizedBox(width: isWide ? 16.0 : 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emoción registrada',
                                  style: TextStyle(
                                    fontSize: isWide ? 14.0 : 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hoy te sientes: ${_feelingToText(todayEmotion!.feeling)}',
                                  style: TextStyle(
                                    fontSize: isWide ? 16.0 : 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (emotionState is EmotionError) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: isWide 
                          ? const EdgeInsets.all(20.0)
                          : const EdgeInsets.all(16.0),
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
                            size: isWide ? 24.0 : 20.0,
                          ),
                          SizedBox(width: isWide ? 16.0 : 12.0),
                          Expanded(
                            child: Text(
                              emotionState.message,
                              style: TextStyle(
                                fontSize: isWide ? 16.0 : 14.0,
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
    );
  }

  Widget _buildAdaptiveEmotionSelector(
    BuildContext context,
    HomeContentState homeState,
    bool hasEmotionToday,
    BoxConstraints constraints,
  ) {
    final double width = constraints.maxWidth;
    final bool isVeryWide = width > 1000;
    final bool isWide = width > 600;
    final bool isCompact = width <= 400;
    
    final double iconSize = isVeryWide ? 56.0 : (isWide ? 48.0 : (isCompact ? 32.0 : 40.0));
    final double spacing = isVeryWide ? 24.0 : (isWide ? 20.0 : (isCompact ? 8.0 : 12.0));
    final double runSpacing = isWide ? 16.0 : 12.0;

    final List<Map<String, dynamic>> emotions = [
      {'emoji': '😢', 'label': 'Terrible', 'feeling': Feeling.terrible},
      {'emoji': '😔', 'label': 'Mal', 'feeling': Feeling.bad},
      {'emoji': '😐', 'label': 'Regular', 'feeling': Feeling.neutral},
      {'emoji': '😊', 'label': 'Bien', 'feeling': Feeling.good},
      {'emoji': '😄', 'label': 'Genial', 'feeling': Feeling.great},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isWide ? 20.0 : 16.0,
        horizontal: isWide ? 16.0 : 12.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: emotions.map((emotion) {
            return _ImprovedFeelingIcon(
              emoji: emotion['emoji'] as String,
              label: emotion['label'] as String,
              feeling: emotion['feeling'] as Feeling,
              isSelected: homeState.selectedFeeling == emotion['feeling'],
              isDisabled: hasEmotionToday,
              iconSize: iconSize,
              isWide: isWide,
              onTap: hasEmotionToday
                  ? null
                  : () => context.read<HomeContentCubit>().selectFeeling(emotion['feeling'] as Feeling),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdaptiveTipsLayout(BoxConstraints constraints, bool isLandscape) {
    final double width = constraints.maxWidth;
    final bool isTablet = width > 600 && width <= 1200;
    final bool isDesktop = width > 1200;
    final tips = DailyTipsManager.getTipsForToday();

    if (isDesktop) {
      final crossAxisCount = width > 1600 ? 4 : 3;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return _TipCard(
            title: tip.title,
            description: tip.description,
            icon: tip.icon,
            onTap: () => _showTipDialog(context, tip),
            isWide: true,
          );
        },
      );
    } else if (isTablet) {
      final crossAxisCount = isLandscape ? 3 : 2;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isLandscape ? 1.2 : 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return _TipCard(
            title: tip.title,
            description: tip.description,
            icon: tip.icon,
            onTap: () => _showTipDialog(context, tip),
            isWide: true,
          );
        },
      );
    } else {
      return SizedBox(
        height: isLandscape ? 120 : 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return _TipCard(
              title: tip.title,
              description: tip.description,
              icon: tip.icon,
              onTap: () => _showTipDialog(context, tip),
              isWide: false,
            );
          },
        ),
      );
    }
  }

  Widget _buildAppointmentSection(BuildContext context, BoxConstraints constraints) {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state.isLoadingState) {
          return _buildAppointmentLoading(constraints);
        }
        
        if (state.isError) {
          return _buildAppointmentError(state.errorMessage, constraints);
        }
        
        final upcomingAppointments = state.upcomingAppointments
            .where((appointment) => 
                appointment.status == AppointmentStatus.confirmed ||
                appointment.status == AppointmentStatus.in_progress)
            .toList();
        
        if (upcomingAppointments.isNotEmpty) {
          final upcomingAppointment = upcomingAppointments.first;
          return _AppointmentCard(appointment: upcomingAppointment, constraints: constraints);
        } else {
          return _buildNoAppointmentsCard(constraints);
        }
      },
    );
  }

  Widget _buildAppointmentLoading(BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: isWide 
            ? const EdgeInsets.all(24.0)
            : const EdgeInsets.all(16.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 24.0 : 20.0,
                height: isWide ? 24.0 : 20.0,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: isWide ? 16.0 : 12.0),
              Text(
                'Cargando citas...',
                style: TextStyle(
                  fontSize: isWide ? 16.0 : 14.0,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentError(String? errorMessage, BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: isWide 
            ? const EdgeInsets.all(24.0)
            : const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: isWide ? 48.0 : 40.0,
            ),
            SizedBox(height: isWide ? 16.0 : 12.0),
            Text(
              'Error al cargar citas',
              style: TextStyle(
                fontSize: isWide ? 18.0 : 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.red,
                fontFamily: 'Poppins',
              ),
            ),
            if (errorMessage != null) ...[
              SizedBox(height: isWide ? 12.0 : 8.0),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: isWide ? 14.0 : 13.0,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: isWide ? 16.0 : 12.0),
            ElevatedButton(
              onPressed: _loadPatientAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24.0 : 20.0,
                  vertical: isWide ? 16.0 : 12.0,
                ),
              ),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: isWide ? 16.0 : 14.0,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointmentsCard(BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth > 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: isWide 
            ? const EdgeInsets.all(24.0)
            : const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: Colors.grey[400],
              size: isWide ? 48.0 : 40.0,
            ),
            SizedBox(height: isWide ? 16.0 : 12.0),
            Text(
              'No tienes citas próximas',
              style: TextStyle(
                fontSize: isWide ? 18.0 : 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: isWide ? 8.0 : 6.0),
            Text(
              'Agenda una cita con tu psicólogo',
              style: TextStyle(
                fontSize: isWide ? 14.0 : 13.0,
                color: Colors.grey,
                fontFamily: 'Poppins',
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

// CARRUSEL DE ARTÍCULOS
class _ArticleCarousel extends StatefulWidget {
  final List<Article> articles;
  final String patientId;
  final BoxConstraints constraints;

  const _ArticleCarousel({
    required this.articles,
    required this.patientId,
    required this.constraints,
  });

  @override
  State<_ArticleCarousel> createState() => _ArticleCarouselState();
}

class _ArticleCarouselState extends State<_ArticleCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _calculateViewportFraction());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed && widget.articles.length > 1) {
        _startTimer();
      }
    });
  }

  double _calculateViewportFraction() {
    final double width = widget.constraints.maxWidth;
    final double height = widget.constraints.maxHeight;
    final bool isLandscape = width > height;
    
    if (isLandscape) {
      if (width > 1200) return 0.2;
      if (width > 800) return 0.25;
      if (width > 600) return 0.33;
      return 0.4;
    } else {
      if (width > 1200) return 0.25;
      if (width > 800) return 0.33;
      if (width > 600) return 0.5;
      return 0.85;
    }
  }

  @override
  void didUpdateWidget(_ArticleCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constraints.maxWidth != widget.constraints.maxWidth) {
      _pageController.dispose();
      _pageController = PageController(viewportFraction: _calculateViewportFraction());
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _timer?.cancel();
      _pageController.dispose();
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

      if (_pageController.hasClients) {
        try {
          if (_currentPage < widget.articles.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }

          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
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

    final bool isWide = widget.constraints.maxWidth > 600;
    final bool isLandscape = widget.constraints.maxWidth > widget.constraints.maxHeight;
    
    return Column(
      children: [
        SizedBox(
          height: isLandscape 
              ? (isWide ? 260.0 : 220.0)
              : (isWide ? 320.0 : 280.0),
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
                padding: EdgeInsets.symmetric(horizontal: isWide ? 12.0 : 8.0),
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
                  isWide: isWide,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (widget.articles.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.articles.length,
              (index) => Container(
                width: isWide ? 10.0 : 8.0,
                height: isWide ? 10.0 : 8.0,
                margin: EdgeInsets.symmetric(horizontal: isWide ? 6.0 : 4.0),
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

// CARD DE ARTÍCULO
class _ArticleCarouselCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool isWide;

  const _ArticleCarouselCard({
    required this.article,
    required this.onTap,
    required this.isWide,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxHeight < 280;
            final bool isVeryCompact = constraints.maxHeight < 240;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    article.imageUrl ?? '',
                    height: isVeryCompact ? 100.0 : (isCompact ? 120.0 : (isWide ? 180.0 : 150.0)),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: isVeryCompact ? 100.0 : (isCompact ? 120.0 : (isWide ? 180.0 : 150.0)),
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
                        height: isVeryCompact ? 100.0 : (isCompact ? 120.0 : (isWide ? 180.0 : 150.0)),
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.article,
                            color: Colors.grey,
                            size: isVeryCompact ? 32.0 : (isCompact ? 36.0 : (isWide ? 48.0 : 40.0)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: isVeryCompact 
                        ? const EdgeInsets.all(8.0)
                        : (isCompact ? const EdgeInsets.all(10.0) : 
                           (isWide ? const EdgeInsets.all(16.0) : const EdgeInsets.all(12.0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: TextStyle(
                            fontSize: isVeryCompact ? 12.0 : 
                                    (isCompact ? 14.0 : (isWide ? 18.0 : 16.0)),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: isVeryCompact ? 2 : (isCompact ? 2 : 2),
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: isVeryCompact ? 4.0 : (isCompact ? 6.0 : 8.0)),
                        
                        if (!isVeryCompact && article.summary != null && article.summary!.isNotEmpty)
                          Expanded(
                            flex: isCompact ? 1 : 2,
                            child: Text(
                              article.summary!,
                              style: TextStyle(
                                fontSize: isCompact ? 11.0 : (isWide ? 14.0 : 13.0),
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                              maxLines: isCompact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        
                        if (isVeryCompact) const Spacer(),
                        
                        _buildArticleInfo(
                          article: article,
                          formattedDate: formattedDate,
                          isVeryCompact: isVeryCompact,
                          isCompact: isCompact,
                          isWide: isWide,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildArticleInfo({
    required Article article,
    required String formattedDate,
    required bool isVeryCompact,
    required bool isCompact,
    required bool isWide,
  }) {
    if (isVeryCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por ${article.fullName ?? 'Autor'}',
            style: TextStyle(
              fontSize: 10.0,
              color: AppConstants.lightAccentColor,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.timer,
                size: 10.0,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 2),
              Text(
                '${article.readingTimeMinutes} min',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 9.0,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Por ${article.fullName ?? 'Autor'}',
                style: TextStyle(
                  fontSize: isCompact ? 11.0 : (isWide ? 13.0 : 12.0),
                  color: AppConstants.lightAccentColor,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: isCompact ? 12.0 : (isWide ? 16.0 : 14.0),
                  color: Colors.grey[600],
                ),
                SizedBox(width: isCompact ? 4.0 : (isWide ? 6.0 : 4.0)),
                Text(
                  '${article.readingTimeMinutes} min',
                  style: TextStyle(
                    fontSize: isCompact ? 11.0 : (isWide ? 13.0 : 12.0),
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isCompact ? 2.0 : 4.0),
        Text(
          formattedDate,
          style: TextStyle(
            fontSize: isCompact ? 10.0 : (isWide ? 12.0 : 11.0),
            color: Colors.grey[500],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

// CARD DE CITA
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final BoxConstraints constraints;

  const _AppointmentCard({
    required this.appointment,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = constraints.maxWidth > 600;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: isWide 
            ? const EdgeInsets.all(20.0)
            : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.psychologistName,
              style: TextStyle(
                fontSize: isWide ? 18.0 : 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isWide ? 8.0 : 6.0),
            Text(
              appointment.psychologistSpecialty,
              style: TextStyle(
                fontSize: isWide ? 16.0 : 14.0,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isWide ? 16.0 : 12.0),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isWide ? 20.0 : 18.0,
                  color: Colors.grey[600],
                ),
                SizedBox(width: isWide ? 16.0 : 12.0),
                Flexible(
                  child: Text(
                    '${appointment.scheduledDateTime.day}/${appointment.scheduledDateTime.month}/${appointment.scheduledDateTime.year}',
                    style: TextStyle(
                      fontSize: isWide ? 16.0 : 14.0,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWide ? 12.0 : 8.0),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isWide ? 20.0 : 18.0,
                  color: Colors.grey[600],
                ),
                SizedBox(width: isWide ? 16.0 : 12.0),
                Flexible(
                  child: Text(
                    '${appointment.scheduledDateTime.hour}:${appointment.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: isWide ? 16.0 : 14.0,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
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

// ÍCONO DE EMOCIÓN
class _ImprovedFeelingIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final Feeling feeling;
  final bool isSelected;
  final bool isDisabled;
  final double iconSize;
  final bool isWide;
  final VoidCallback? onTap;

  const _ImprovedFeelingIcon({
    required this.emoji,
    required this.label,
    required this.feeling,
    required this.isSelected,
    required this.isDisabled,
    required this.iconSize,
    required this.isWide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isWide ? 12.0 : 8.0,
          horizontal: isWide ? 12.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppConstants.primaryColor 
                : (isDisabled ? Colors.grey.shade300 : Colors.transparent),
            width: 2,
          ),
        ),
        child: Opacity(
          opacity: isDisabled && !isSelected ? 0.4 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(iconSize / 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: iconSize * 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isWide ? 8.0 : 6.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: isWide ? 14.0 : 12.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade700),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                SizedBox(height: isWide ? 6.0 : 4.0),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: iconSize * 0.6,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// CARD DE TIP
class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isWide;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktopOrTablet = isWide;
    
    return Container(
      margin: isDesktopOrTablet 
          ? EdgeInsets.zero 
          : const EdgeInsets.only(right: 12.0),
      width: isDesktopOrTablet 
          ? null 
          : 160.0,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: isDesktopOrTablet 
                ? const EdgeInsets.all(16.0)
                : const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: AppConstants.primaryColor,
                  size: isDesktopOrTablet ? 32.0 : 28.0,
                ),
                SizedBox(height: isDesktopOrTablet ? 12.0 : 8.0),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktopOrTablet ? 16.0 : 14.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: isDesktopOrTablet ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isDesktopOrTablet ? 8.0 : 6.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppConstants.primaryColor,
                      size: isDesktopOrTablet ? 18.0 : 16.0,
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