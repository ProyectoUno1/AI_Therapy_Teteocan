import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/services/exercise_feelings_service.dart';
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
  bool _isSaving = false;
  int _elapsedSeconds = 0;
  late int _totalSeconds;
  Timer? _timer;
  TextEditingController _noteController = TextEditingController();
  String _selectedFeeling = 'neutral';
  int _intensity = 5;
  
  final ExerciseFeelingsService _feelingsService = ExerciseFeelingsService();

  final Map<String, IconData> _feelings = {
    'muy_mal': Icons.sentiment_very_dissatisfied,
    'mal': Icons.sentiment_dissatisfied,
    'neutral': Icons.sentiment_neutral,
    'bien': Icons.sentiment_satisfied,
    'muy_bien': Icons.sentiment_very_satisfied,
  };

  final Map<String, String> _feelingLabels = {
    'muy_mal': 'Muy Mal',
    'mal': 'Mal',
    'neutral': 'Neutral',
    'bien': 'Bien',
    'muy_bien': 'Muy Bien',
  };

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

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _feelingsService.saveExerciseFeeling(
        patientId: user.uid,
        exerciseTitle: widget.exercise.title,
        exerciseDuration: widget.exercise.duration.inMinutes,
        exerciseDifficulty: widget.exercise.difficulty,
        feeling: _selectedFeeling,
        intensity: _intensity,
        notes: _noteController.text.trim(),
        completedAt: DateTime.now(),
        metadata: {
          'totalSeconds': _totalSeconds,
          'elapsedSeconds': _elapsedSeconds,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflexión guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
            final bool isTablet = constraints.maxWidth > 600;
            final double paddingValue = isTablet ? 24.0 : 16.0;
            final double iconSize = isTablet ? 80.0 : 64.0;
            final double timerFontSize = isTablet ? 56.0 : 48.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(paddingValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(context, iconSize, isLandscape),
                    SizedBox(height: isTablet ? 24.0 : 20.0),
                    
                    // Exercise Info
                    _buildExerciseInfo(context),
                    SizedBox(height: isTablet ? 24.0 : 20.0),
                    
                    // Description
                    _buildDescriptionSection(isTablet),
                    SizedBox(height: isTablet ? 30.0 : 24.0),

                    // Dynamic Content based on exercise state
                    _buildDynamicContent(
                      context, 
                      timerFontSize, 
                      isLandscape, 
                      isTablet
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, double iconSize, bool isLandscape) {
    return Container(
      height: isLandscape ? 150.0 : 200.0,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.fitness_center,
        size: iconSize,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildExerciseInfo(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 400;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: isCompact ? 18.0 : 20.0),
                  SizedBox(width: isCompact ? 6.0 : 8.0),
                  Flexible(
                    child: Text(
                      '${widget.exercise.duration.inMinutes} minutos',
                      style: TextStyle(fontSize: isCompact ? 14.0 : 16.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isCompact ? 8.0 : 12.0),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8.0 : 12.0,
                  vertical: isCompact ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  widget.exercise.difficulty,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: isCompact ? 12.0 : 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: isTablet ? 22.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          widget.exercise.description,
          style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
        ),
      ],
    );
  }

  Widget _buildDynamicContent(BuildContext context, double timerFontSize, bool isLandscape, bool isTablet) {
    if (_isExerciseRunning || _isExerciseCompleted) {
      return _buildProgressSection(context, timerFontSize, isLandscape, isTablet);
    } else if (!_isExerciseCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionsSection(),
          SizedBox(height: isTablet ? 30.0 : 24.0),
          _buildStartButton(),
        ],
      );
    } else {
      return _buildCompletionSection(context, isLandscape, isTablet);
    }
  }

  Widget _buildProgressSection(BuildContext context, double timerFontSize, bool isLandscape, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso del Ejercicio',
          style: TextStyle(
            fontSize: isTablet ? 22.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isTablet ? 24.0 : 20.0),
        Container(
          padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                _formatTime(_isExerciseRunning ? _elapsedSeconds : _totalSeconds),
                style: TextStyle(
                  fontSize: timerFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: isTablet ? 24.0 : 20.0),
              LinearProgressIndicator(
                value: _getProgress(),
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
                minHeight: 8,
              ),
              SizedBox(height: 10),
              Text(
                '${(_getProgress() * 100).toStringAsFixed(0)}% completado',
                style: TextStyle(fontSize: isTablet ? 18.0 : 16.0),
              ),
              SizedBox(height: isTablet ? 24.0 : 20.0),
              if (_isExerciseRunning)
                _buildExerciseControls(context, isLandscape),
              if (!_isExerciseRunning && _elapsedSeconds > 0 && !_isExerciseCompleted)
                _buildResumeButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseControls(BuildContext context, bool isLandscape) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool useHorizontalLayout = orientation == Orientation.landscape || isLandscape;
        
        if (useHorizontalLayout) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildControlButton(
                  onPressed: _pauseExercise,
                  icon: Icons.pause,
                  label: 'Pausar',
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildControlButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _isExerciseRunning = false;
                      _elapsedSeconds = 0;
                    });
                  },
                  icon: Icons.stop,
                  label: 'Detener',
                  color: Colors.red,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildControlButton(
                onPressed: _pauseExercise,
                icon: Icons.pause,
                label: 'Pausar',
                color: Colors.orange,
                isFullWidth: true,
              ),
              SizedBox(height: 10),
              _buildControlButton(
                onPressed: () {
                  _timer?.cancel();
                  setState(() {
                    _isExerciseRunning = false;
                    _elapsedSeconds = 0;
                  });
                },
                icon: Icons.stop,
                label: 'Detener',
                color: Colors.red,
                isFullWidth: true,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildResumeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resumeExercise,
        icon: Icon(Icons.play_arrow),
        label: Text('Continuar'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrucciones',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 22.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        _buildInstructionStep(1, 'Encuentra un lugar tranquilo y cómodo.'),
        _buildInstructionStep(2, 'Asegúrate de tener el tiempo necesario sin interrupciones.'),
        _buildInstructionStep(3, 'Sigue las instrucciones del ejercicio paso a paso.'),
        _buildInstructionStep(4, 'Mantén una actitud abierta y receptiva.'),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startExercise,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          'Comenzar Ejercicio',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 20.0 : 18.0),
        ),
      ),
    );
  }

  Widget _buildCompletionSection(BuildContext context, bool isLandscape, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '¡Ejercicio Completado!',
            style: TextStyle(
              fontSize: isTablet ? 28.0 : 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isTablet ? 24.0 : 20.0),
        
        // Feeling Selector
        _buildFeelingSelector(context, isLandscape, isTablet),
        SizedBox(height: isTablet ? 24.0 : 20.0),
        
        // Intensity Slider
        _buildIntensitySlider(context, isTablet),
        SizedBox(height: isTablet ? 24.0 : 20.0),
        
        // Notes Section
        _buildNotesSection(context, isTablet),
        SizedBox(height: isTablet ? 24.0 : 20.0),
        
        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildFeelingSelector(BuildContext context, bool isLandscape, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo te sentiste durante el ejercicio?',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool useCompactLayout = constraints.maxWidth < 400;
            final double iconSize = useCompactLayout ? 24.0 : 32.0;
            final double spacing = useCompactLayout ? 8.0 : 12.0;

            return Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: spacing,
              runSpacing: spacing,
              children: _feelings.entries.map((entry) {
                final isSelected = _selectedFeeling == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFeeling = entry.key;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(useCompactLayout ? 8.0 : 12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entry.value,
                          size: iconSize,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _feelingLabels[entry.key]!,
                        style: TextStyle(
                          fontSize: useCompactLayout ? 10.0 : 12.0,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIntensitySlider(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensidad del sentimiento:',
          style: TextStyle(
            fontSize: isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Text('1', style: TextStyle(fontSize: isTablet ? 16.0 : 14.0)),
            Expanded(
              child: Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _intensity.toString(),
                onChanged: (value) {
                  setState(() {
                    _intensity = value.toInt();
                  });
                },
              ),
            ),
            Text('10', style: TextStyle(fontSize: isTablet ? 16.0 : 14.0)),
          ],
        ),
        Center(
          child: Text(
            'Intensidad: $_intensity',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparte tus reflexiones y experiencias:',
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 14.0,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Escribe aquí tus reflexiones...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveNote,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.green,
            ),
            child: _isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Guardar Reflexión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(
              'Omitir y volver',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
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
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(instruction, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}