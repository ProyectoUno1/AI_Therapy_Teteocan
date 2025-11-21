// lib/presentation/psychologist/views/patient_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/data/models/exercise_feeling_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/emotion_repository.dart';
import 'package:ai_therapy_teteocan/core/services/exercise_feelings_service.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/data/datasources/emotion_data_source.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';


class PatientProgressScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final int totalSessions;

  const PatientProgressScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.totalSessions,
  });

  @override
  State<PatientProgressScreen> createState() => _PatientProgressScreenState();
}

class _PatientProgressScreenState extends State<PatientProgressScreen> {
  bool _isLoading = true;
  List<Emotion> _emotions = [];
  List<ExerciseFeelingModel> _exercises = [];
  String _selectedPeriod = '30'; 

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

 Future<void> _loadProgressData() async {
  setState(() => _isLoading = true);

  try {
    final days = int.parse(_selectedPeriod);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    print('🔍 Loading progress for patient: ${widget.patientId}');
    print('📅 Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

    List<Emotion> emotions = [];
    List<ExerciseFeelingModel> exercises = [];

    // ✅ Cargar emociones usando HTTP directamente
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/patient-management/patients/${widget.patientId}/emotions'
          '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}'
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      print('📊 Emotions Response Status: ${response.statusCode}');
      print('📊 Emotions Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> emotionsJson = json.decode(response.body);
        emotions = emotionsJson.map((json) => Emotion.fromJson(json)).toList();
        print('✅ Loaded ${emotions.length} emotions');
      } else {
        print('⚠️ Emotions request failed: ${response.statusCode}');
      }
    } catch (emotionError, stack) {
      print('❌ Error loading emotions: $emotionError');
      print('📚 Stack trace: $stack');
    }

    // ✅ Cargar ejercicios
    try {
      final exerciseService = ExerciseFeelingsService();
      final allExercises = await exerciseService.getExerciseHistory(
        patientId: widget.patientId,
        limit: 100,
      );

      exercises = allExercises.where((exercise) {
        return exercise.completedAt.isAfter(startDate) &&
            exercise.completedAt.isBefore(endDate);
      }).toList();
      
      print('✅ Loaded ${exercises.length} exercises');
    } catch (exerciseError, stack) {
      print('❌ Error loading exercises: $exerciseError');
      print('📚 Stack trace: $stack');
    }

    if (mounted) {
      setState(() {
        _emotions = emotions;
        _exercises = exercises;
        _isLoading = false;
      });
    }
  } catch (e, stackTrace) {
    print('❌ Error general: $e');
    print('📚 StackTrace: $stackTrace');
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Error al cargar datos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _loadProgressData,
          ),
        ),
      );
    }
  }
}

Future<String> _getAuthToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return token ?? '';
    }
    return '';
  } catch (e) {
    print('❌ Error getting auth token: $e');
    return '';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso del Paciente',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.patientName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgressData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildEmotionsChart(),
                    const SizedBox(height: 24),
                    _buildExerciseFrequencyChart(),
                    const SizedBox(height: 24),
                    _buildIntensityChart(),
                    const SizedBox(height: 24),
                    _buildEmotionDistribution(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildPeriodButton('7', '7 días'),
          _buildPeriodButton('30', '30 días'),
          _buildPeriodButton('90', '90 días'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadProgressData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final avgIntensity = _calculateAverageIntensity();
    final emotionDays = _emotions.length;
    final exerciseDays = _exercises.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es muy pequeño, usar Column en lugar de Row
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              _buildSummaryCard(
                'Emociones',
                '$emotionDays',
                'registros',
                Icons.favorite,
                Colors.pink,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                'Ejercicios',
                '$exerciseDays',
                'completados',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                'Intensidad',
                avgIntensity.toStringAsFixed(1),
                'promedio',
                Icons.trending_up,
                Colors.orange,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Emociones',
                '$emotionDays',
                'registros',
                Icons.favorite,
                Colors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Ejercicios',
                '$exerciseDays',
                'completados',
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Intensidad',
                avgIntensity.toStringAsFixed(1),
                'promedio',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsChart() {
    if (_emotions.isEmpty) {
      return _buildEmptyState('Sin emociones registradas');
    }

    return _buildChartContainer(
      title: 'Evolución Emocional',
      icon: Icons.psychology,
      color: Colors.purple,
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _emotions.length) {
                      final date = _emotions[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 10,
            lineBarsData: [
              LineChartBarData(
                spots: _emotions.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value.intensity ?? 0).toDouble(),
                  );
                }).toList(),
                isCurved: true,
                color: Colors.purple,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.purple.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseFrequencyChart() {
    if (_exercises.isEmpty) {
      return _buildEmptyState('Sin ejercicios registrados');
    }

    // Agrupar ejercicios por día
    final exercisesByDay = <DateTime, int>{};
    for (var exercise in _exercises) {
      final date = DateTime(
        exercise.completedAt.year,
        exercise.completedAt.month,
        exercise.completedAt.day,
      );
      exercisesByDay[date] = (exercisesByDay[date] ?? 0) + 1;
    }

    final sortedDates = exercisesByDay.keys.toList()..sort();

    return _buildChartContainer(
      title: 'Frecuencia de Ejercicios',
      icon: Icons.bar_chart,
      color: Colors.blue,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (exercisesByDay.values.reduce((a, b) => a > b ? a : b) + 2)
                .toDouble(),
            barGroups: sortedDates.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: exercisesByDay[entry.value]!.toDouble(),
                    color: Colors.blue,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < sortedDates.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(sortedDates[value.toInt()]),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityChart() {
    if (_exercises.isEmpty) {
      return _buildEmptyState('Sin datos de intensidad');
    }

    return _buildChartContainer(
      title: 'Intensidad de Ejercicios',
      icon: Icons.speed,
      color: Colors.orange,
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < _exercises.length) {
                      final date = _exercises[value.toInt()].completedAt;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 10,
            lineBarsData: [
              LineChartBarData(
                spots: _exercises.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.intensity.toDouble(),
                  );
                }).toList(),
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orange.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionDistribution() {
    if (_emotions.isEmpty) {
      return _buildEmptyState('Sin datos de emociones');
    }

    // Contar emociones
    final emotionCounts = <String, int>{};
    for (var emotion in _emotions) {
      final feelingKey = emotion.feeling.toString().split('.').last;
      emotionCounts[feelingKey] = (emotionCounts[feelingKey] ?? 0) + 1;
    }

    final total = _emotions.length;

    return _buildChartContainer(
      title: 'Distribución de Emociones',
      icon: Icons.pie_chart,
      color: Colors.green,
      child: Column(
        children: emotionCounts.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getEmotionLabel(entry.key),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Text(
                        '${entry.value} ($percentage%)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: entry.value / total,
                  backgroundColor: Colors.grey[200],
                  color: _getEmotionColor(entry.key),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔥 ESTE ES EL MÉTODO CRÍTICO QUE CAUSABA EL OVERFLOW (línea 684)
  Widget _buildChartContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SOLUCIÓN: Usar Row con Expanded para evitar overflow
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageIntensity() {
    if (_emotions.isEmpty && _exercises.isEmpty) return 0;

    final emotionIntensities = _emotions.map((e) => e.intensity).whereType<num>().toList();
    final exerciseIntensities = _exercises.map((e) => e.intensity).whereType<num>().toList();
    final allIntensities = [...emotionIntensities, ...exerciseIntensities];

    if (allIntensities.isEmpty) return 0;

    return allIntensities.reduce((a, b) => a + b) / allIntensities.length;
  }

  String _getEmotionLabel(String feeling) {
    final labels = {
      'happy': '😊 Feliz',
      'sad': '😢 Triste',
      'angry': '😠 Enojado',
      'anxious': '😰 Ansioso',
      'calm': '😌 Tranquilo',
      'excited': '🤩 Emocionado',
      'neutral': '😐 Neutral',
    };
    return labels[feeling] ?? feeling;
  }

  Color _getEmotionColor(String feeling) {
    final colors = {
      'happy': Colors.yellow[700]!,
      'sad': Colors.blue[700]!,
      'angry': Colors.red[700]!,
      'anxious': Colors.orange[700]!,
      'calm': Colors.green[700]!,
      'excited': Colors.purple[700]!,
      'neutral': Colors.grey[700]!,
    };
    return colors[feeling] ?? Colors.grey;
  }
}