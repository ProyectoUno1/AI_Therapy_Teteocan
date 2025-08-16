// lib/presentation/psychologist/bloc/psychologist_info_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_state.dart';
import 'package:ai_therapy_teteocan/domain/usecases/psychologist/psychologist_setup_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/psychologist/psychologist_get_usecase.dart'; 
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart'; 

class PsychologistInfoBloc extends Bloc<PsychologistInfoEvent, PsychologistInfoState> {
  final PsychologistRepository psychologistRepository;
  
  final PsychologistSetupUseCase _setupUsecase;
  final PsychologistGetUsecase _getUsecase; 

  PsychologistInfoBloc({required this.psychologistRepository})
      : _setupUsecase = PsychologistSetupUseCase(psychologistRepository),
        _getUsecase = PsychologistGetUsecase(psychologistRepository), 
        super(PsychologistInfoInitial()) {
    on<SetupProfessionalInfoEvent>(_onSetupProfessionalInfo);
    on<LoadPsychologistInfoEvent>(_onLoadProfessionalInfo); 
  }

  // Método para guardar/actualizar la información 
  Future<void> _onSetupProfessionalInfo(
    SetupProfessionalInfoEvent event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    emit(PsychologistInfoLoading());
    try {
      await _setupUsecase(
        uid: event.uid,
        fullName: event.fullName,
        professionalTitle: event.professionalTitle,
        licenseNumber: event.licenseNumber,
        yearsExperience: event.yearsExperience,
        description: event.description,
        education: event.education,
        certifications: event.certifications,
        profilePictureUrl: event.profilePictureUrl,
        email: event.email,
        selectedSpecialty: event.selectedSpecialty,
        selectedSubSpecialties: event.selectedSubSpecialties,
        schedule: event.schedule,
        isAvailable: event.isAvailable, 
      );
      emit(PsychologistInfoSaved());
    } catch (e) {
      emit(PsychologistInfoError(message: e.toString()));
    }
  }

  
  Future<void> _onLoadProfessionalInfo(
    LoadPsychologistInfoEvent event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    emit(PsychologistInfoLoading());
    try {
      final psychologist = await _getUsecase(uid: event.uid); 
      if (psychologist != null) {
        emit(PsychologistInfoLoaded(psychologist: psychologist));
      } else {
        emit(PsychologistInfoInitial());
      }
    } catch (e) {
      emit(PsychologistInfoError(message: e.toString()));
    }
  }
}