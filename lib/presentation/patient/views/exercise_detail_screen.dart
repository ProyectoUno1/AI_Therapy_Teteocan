import 'package:flutter/material.dart';
import 'dart:async'; // <-- Agregar esta importación
import '../widgets/daily_exercise_carousel.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final DailyExercise exercise;

  const ExerciseDetailScreen({Key? key, required this.exercise})
    : super(key: key);

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isExerciseCompleted = false;
  bool _isExerciseRunning = false;
  int _elapsedSeconds = 0;
  late int _totalSeconds;
  Timer? _timer;
  TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.exercise.duration.inSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isExerciseRunning = true;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });

      if (_elapsedSeconds >= _totalSeconds) {
        _timer?.cancel();
        setState(() {
          _isExerciseRunning = false;
          _isExerciseCompleted = true;
        });
      }
    });
  }

  void _pauseExercise() {
    _timer?.cancel();
    setState(() {
      _isExerciseRunning = false;
    });
  }

  void _resumeExercise() {
    _startExercise();
  }

  void _saveNote() {
    // Aquí puedes guardar la nota en una base de datos o donde necesites
    String note = _noteController.text;
    print('Nota guardada: $note');
    
    // Mostrar mensaje de éxito y regresar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota guardada exitosamente'))
    );
    
    // Regresar a la pantalla anterior después de guardar
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return _elapsedSeconds / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 8),
                      Text('${widget.exercise.duration.inMinutes} minutos'),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      widget.exercise.difficulty,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Descripción',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(widget.exercise.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              
              // Sección del cronómetro
              if (_isExerciseRunning || _isExerciseCompleted) ...[
                const Text(
                  'Progreso del Ejercicio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(_isExerciseRunning ? _elapsedSeconds : _totalSeconds),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: _getProgress(),
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(_getProgress() * 100).toStringAsFixed(0)}% completado',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      if (_isExerciseRunning)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pauseExercise,
                              icon: const Icon(Icons.pause),
                              label: const Text('Pausar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                _timer?.cancel();
                                setState(() {
                                  _isExerciseRunning = false;
                                  _elapsedSeconds = 0;
                                });
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Detener'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      if (!_isExerciseRunning && _elapsedSeconds > 0 && !_isExerciseCompleted)
                        ElevatedButton.icon(
                          onPressed: _resumeExercise,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Continuar'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              // Sección de instrucciones (solo mostrar si no se ha completado el ejercicio)
              if (!_isExerciseCompleted) ...[
                const Text(
                  'Instrucciones',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildInstructionStep(
                  1,
                  'Encuentra un lugar tranquilo y cómodo.',
                ),
                _buildInstructionStep(
                  2,
                  'Asegúrate de tener el tiempo necesario sin interrupciones.',
                ),
                _buildInstructionStep(
                  3,
                  'Sigue las instrucciones del ejercicio paso a paso.',
                ),
                _buildInstructionStep(
                  4,
                  'Mantén una actitud abierta y receptiva.',
                ),
                const SizedBox(height: 30),
              ],
              
              // Sección para agregar nota (solo mostrar cuando se complete el ejercicio)
              if (_isExerciseCompleted) ...[
                const Text(
                  '¡Ejercicio Completado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Cómo te sentiste durante el ejercicio?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comparte tus reflexiones y experiencias:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Escribe aquí tus reflexiones...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Guardar Nota',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Omitir y volver',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
              
              // Botón para comenzar ejercicio (solo mostrar si no se ha iniciado)
              if (!_isExerciseRunning && !_isExerciseCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startExercise,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Comenzar Ejercicio',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}