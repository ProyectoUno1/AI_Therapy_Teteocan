// lib/presentation/psychologist/bloc/psychologist_info_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_state.dart';
import 'package:ai_therapy_teteocan/domain/usecases/psychologist/psychologist_setup_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/psychologist/psychologist_get_usecase.dart'; 
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart'; 
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    on<PsychologistProfilePictureUploadRequested>(_onPictureUploadRequested);
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
        username: event.fullName,
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
        price: event.price, 
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

  Future<void> _onPictureUploadRequested(
    PsychologistProfilePictureUploadRequested event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    final currentState = state;
    
    // Obtenemos el psicólogo actual y emitimos Loading para feedback
    PsychologistModel? currentPsychologist;
    if (currentState is PsychologistInfoLoaded) {
      currentPsychologist = currentState.psychologist;
    }
    emit(PsychologistInfoLoading()); 

    try {
      final newUrl = await psychologistRepository.uploadProfilePicture(event.imagePath);
      final currentUid = currentPsychologist?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUid == null) {
          throw Exception('No se pudo obtener el UID del psicólogo para actualizar el perfil.');
      }
      final psychologist = await _getUsecase(uid: currentUid); 
      
      if (psychologist != null) {
        emit(PsychologistInfoLoaded(psychologist: psychologist));
      } else {
        if (currentPsychologist != null) {
             final updatedPsychologist = currentPsychologist.copyWith(profilePictureUrl: newUrl);
             emit(PsychologistInfoLoaded(psychologist: updatedPsychologist));
        } else {
             emit(PsychologistInfoError(message: 'Foto subida, pero fallo al recargar los datos.'));
        }
      }
      
    } catch (e) {
      emit(PsychologistInfoError(message: 'Error al subir la foto: ${e.toString()}'));

      if (currentPsychologist != null) {
        emit(PsychologistInfoLoaded(psychologist: currentPsychologist)); 
      }
    }
  }
}

  
