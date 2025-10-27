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

  /// Guardar/actualizar información profesional
  Future<void> _onSetupProfessionalInfo(
    SetupProfessionalInfoEvent event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    emit(PsychologistInfoLoading());
    
    try {
      print('💾 Guardando información profesional...');
      print('📋 UID: ${event.uid}');
      print('👤 Nombre: ${event.fullName}');
      print('📸 Imagen URL: ${event.profilePictureUrl}');
      
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
      
      print('✅ Información guardada exitosamente');
      emit(PsychologistInfoSaved());
      
    } catch (e) {
      print('❌ Error guardando información: $e');
      emit(PsychologistInfoError(message: e.toString()));
    }
  }

  /// Cargar información profesional existente
  Future<void> _onLoadProfessionalInfo(
    LoadPsychologistInfoEvent event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    print('🔍 Cargando información del psicólogo: ${event.uid}');
    emit(PsychologistInfoLoading());
    
    try {
      final psychologist = await _getUsecase(uid: event.uid); 
      
      if (psychologist != null) {
        print('✅ Psicólogo cargado exitosamente');
        print('👤 Nombre: ${psychologist.fullName}');
        print('📧 Email: ${psychologist.email}');
        print('🎓 Título: ${psychologist.professionalTitle}');
        print('📋 Cédula: ${psychologist.professionalLicense}');
        print('📸 Imagen: ${psychologist.profilePictureUrl}');
        
        emit(PsychologistInfoLoaded(psychologist: psychologist));
      } else {
        print('⚠️ No se encontró información del psicólogo');
        emit(PsychologistInfoError(message: 'No se encontró información del psicólogo'));
      }
    } catch (e) {
      print('❌ Error cargando psicólogo: $e');
      emit(PsychologistInfoError(message: e.toString()));
    }
  }

  /// Subir foto de perfil
  Future<void> _onPictureUploadRequested(
    PsychologistProfilePictureUploadRequested event,
    Emitter<PsychologistInfoState> emit,
  ) async {
    final currentState = state;
    
    // Guardar psicólogo actual antes de emitir loading
    PsychologistModel? currentPsychologist;
    if (currentState is PsychologistInfoLoaded) {
      currentPsychologist = currentState.psychologist;
    }
    
    emit(PsychologistInfoLoading()); 

    try {
      print('📤 Subiendo imagen de perfil...');
      
      // Subir la imagen y obtener la URL
      final newUrl = await psychologistRepository.uploadProfilePicture(event.imagePath);
      
      print('✅ Imagen subida exitosamente: $newUrl');
      
      // Obtener UID actual
      final currentUid = currentPsychologist?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUid == null) {
        throw Exception('No se pudo obtener el UID del psicólogo');
      }
      
      // Recargar datos actualizados desde Firestore
      print('🔄 Recargando datos del psicólogo...');
      final psychologist = await _getUsecase(uid: currentUid); 
      
      if (psychologist != null) {
        print('✅ Datos recargados exitosamente');
        emit(PsychologistInfoLoaded(psychologist: psychologist));
      } else {
        // Si no se pueden recargar, actualizar solo la URL localmente
        if (currentPsychologist != null) {
          final updatedPsychologist = currentPsychologist.copyWith(
            profilePictureUrl: newUrl
          );
          emit(PsychologistInfoLoaded(psychologist: updatedPsychologist));
        } else {
          emit(PsychologistInfoError(message: 'Foto subida, pero no se pudieron recargar los datos'));
        }
      }
      
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      emit(PsychologistInfoError(message: 'Error al subir la foto: ${e.toString()}'));

      // Restaurar estado anterior si hay error
      if (currentPsychologist != null) {
        emit(PsychologistInfoLoaded(psychologist: currentPsychologist)); 
      }
    }
  }
}