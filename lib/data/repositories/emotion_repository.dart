// lib/data/repositories/emotion_repository.dart
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/data/datasources/emotion_data_source.dart';

abstract class EmotionRepository {
  Future<void> saveEmotion(Emotion emotion);
  Future<List<Emotion>> getPatientEmotions(String patientId);
  Future<Emotion?> getTodayEmotion(String patientId);
  Future<List<Emotion>> getEmotionsByDateRange(String patientId, DateTime start, DateTime end);
}

class EmotionRepositoryImpl implements EmotionRepository {
  final EmotionDataSource dataSource;

  EmotionRepositoryImpl({required this.dataSource});

  @override
  Future<void> saveEmotion(Emotion emotion) async {
    return await dataSource.saveEmotion(emotion);
  }

  @override
  Future<List<Emotion>> getPatientEmotions(String patientId) async {
    return await dataSource.getPatientEmotions(patientId);
  }

  @override
  Future<Emotion?> getTodayEmotion(String patientId) async {
    return await dataSource.getTodayEmotion(patientId);
  }

  @override
  Future<List<Emotion>> getEmotionsByDateRange(String patientId, DateTime start, DateTime end) async {
    return await dataSource.getEmotionsByDateRange(patientId, start, end);
  }
}