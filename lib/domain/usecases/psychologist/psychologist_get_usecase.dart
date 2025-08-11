// lib/domain/usecases/psychologist/psychologist_get_usecase.dart

import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart';

class PsychologistGetUsecase {
  final PsychologistRepository _repository;

  PsychologistGetUsecase(this._repository);

  // El usecase solo tiene un método para ejecutar la lógica de obtener el psicólogo
  Future<PsychologistModel?> call({required String uid}) async {
    return await _repository.getPsychologistInfo(uid);
  }
}