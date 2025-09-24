import 'package:ai_therapy_teteocan/presentation/patient/views/exercise_detail_screen.dart';
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
    return Container(
      height: 200,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exercise.difficulty,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.duration.inMinutes} min',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
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
                          child: const Text('Comenzar'),
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

