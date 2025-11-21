import 'package:ai_therapy_teteocan/presentation/patient/views/exercise_detail_screen.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DailyExercise {
  final String title;
  final String description;
  final String imageUrl;
  final Duration duration;
  final String difficulty;

  DailyExercise({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.difficulty,
  });
}

class DailyExerciseCarousel extends StatefulWidget {
  DailyExerciseCarousel({Key? key}) : super(key: key);

  @override
  _DailyExerciseCarouselState createState() => _DailyExerciseCarouselState();
}

class _DailyExerciseCarouselState extends State<DailyExerciseCarousel> {
  PageController? _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isDisposed = false;

  // Lista de ejercicios
  final List<DailyExercise> dailyExercises = [
    DailyExercise(
      title: 'Respiración Consciente',
      description:
          'Ejercicio de respiración profunda para reducir el estrés y la ansiedad',
      imageUrl: 'assets/images/breathing.png',
      duration: const Duration(minutes: 5),
      difficulty: 'Fácil',
    ),
    DailyExercise(
      title: 'Meditación Guiada',
      description:
          'Sesión de meditación para encontrar calma y claridad mental',
      imageUrl: 'assets/images/meditation.png',
      duration: const Duration(minutes: 10),
      difficulty: 'Intermedio',
    ),
    DailyExercise(
      title: 'Ejercicio de Gratitud',
      description:
          'Practica el reconocimiento de aspectos positivos en tu vida',
      imageUrl: 'assets/images/gratitude.png',
      duration: const Duration(minutes: 3),
      difficulty: 'Fácil',
    ),
    DailyExercise(
      title: 'Visualización Positiva',
      description: 'Imagina y visualiza escenarios positivos para tu bienestar',
      imageUrl: 'assets/images/visualization.png',
      duration: const Duration(minutes: 7),
      difficulty: 'Intermedio',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    // Retrasamos el inicio del timer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDisposed) {
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
    // Incrementar el intervalo para reducir la carga
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      if (_pageController != null && mounted) {
        try {
          if (_currentPage < dailyExercises.length - 1) {
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
    // ✅ Obtener altura responsive
    final cardHeight = ResponsiveUtils.getCardHeight(context, 200);
    
    return Container(
      height: cardHeight,
      child: PageView.builder(
        controller: _pageController!,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: dailyExercises.length,
        itemBuilder: (context, index) {
          final exercise = dailyExercises[index];
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getHorizontalSpacing(context, 8),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 15),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: ResponsiveUtils.getCardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ HEADER ROW - Con mejor control de espacio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ Título con Flexible para evitar overflow
                        Flexible(
                          flex: 2,
                          child: ResponsiveText(
                            exercise.title,
                            baseFontSize: 16, // Reducido de 18
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveUtils.getHorizontalSpacing(context, 8),
                        ),
                        // ✅ Badge de dificultad - compacto
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getHorizontalSpacing(context, 6),
                              vertical: ResponsiveUtils.getVerticalSpacing(context, 3),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getBorderRadius(context, 12),
                              ),
                            ),
                            child: ResponsiveText(
                              exercise.difficulty,
                              baseFontSize: 11, // Reducido de 12
                              color: Theme.of(context).primaryColor,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ResponsiveSpacing(8),
                    
                    // ✅ Descripción responsive
                    ResponsiveText(
                      exercise.description,
                      baseFontSize: 13, // Reducido de 14
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // ✅ FOOTER ROW - ESTA ERA LA LÍNEA 191 QUE CAUSABA EL PROBLEMA
                    Row(
                      children: [
                        // ✅ Ícono de timer más pequeño
                        Icon(
                          Icons.timer,
                          size: ResponsiveUtils.getIconSize(context, 14), // Reducido de 16
                          color: Colors.grey[600],
                        ),
                        SizedBox(
                          width: ResponsiveUtils.getHorizontalSpacing(context, 4),
                        ),
                        // ✅ Texto de duración con Flexible
                        Flexible(
                          child: ResponsiveText(
                            '${exercise.duration.inMinutes} min',
                            baseFontSize: 12, // Reducido de 14
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                        // ✅ Botón más compacto
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExerciseDetailScreen(exercise: exercise),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getHorizontalSpacing(context, 8),
                              vertical: ResponsiveUtils.getVerticalSpacing(context, 4),
                            ),
                            minimumSize: Size(
                              ResponsiveUtils.getResponsiveWidth(
                                context,
                                mobile: 70,
                                tablet: 80,
                                desktop: 90,
                              ),
                              ResponsiveUtils.getButtonHeight(context) * 0.7, // Más pequeño
                            ),
                          ),
                          child: ResponsiveText(
                            'Comenzar',
                            baseFontSize: 12, // Reducido de 14
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}