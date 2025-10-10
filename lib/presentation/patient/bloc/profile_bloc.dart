import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/patient_profile_repository.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_event.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final PatientProfileRepository _repository;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfilePictureUploadRequested>(_onPictureUploadRequested);
    on<ProfilePictureUpdated>(_onPictureUpdated);
    on<ProfileInfoUpdated>(_onInfoUpdated);
    on<ProfileNotificationSettingsUpdated>(_onNotificationSettingsUpdated);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final data = await _repository.fetchProfileData();
      final profile = PatientProfileData.fromMap(data);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onPictureUploadRequested(
    ProfilePictureUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(ProfileLoading()); 
    }
    
    try {
      final newUrl = await _repository.uploadProfilePicture(event.imagePath);
      final data = await _repository.fetchProfileData();
      final profile = PatientProfileData.fromMap(data);
      
      emit(ProfileUpdateSuccess(profile)); 
      emit(ProfileLoaded(profile)); 
      
    } catch (e) {
      emit(ProfileError('Error al subir la foto: ${e.toString()}'));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }


  Future<void> _onPictureUpdated(
    ProfilePictureUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    
    try {
      await _repository.updateProfile(
        field: 'profile_picture_url',
        value: event.newUrl,
      );
      final data = await _repository.fetchProfileData();
      final profile = PatientProfileData.fromMap(data);
      
      emit(ProfileUpdateSuccess(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
      
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onInfoUpdated(
    ProfileInfoUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    
    try {
      for (var entry in event.updatedFields.entries) {
        await _repository.updateProfile(
          field: entry.key,
          value: entry.value,
        );
      }
      
      // Obtener datos actualizados
      final data = await _repository.fetchProfileData();
      final profile = PatientProfileData.fromMap(data);
      
      emit(ProfileUpdateSuccess(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
      
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onNotificationSettingsUpdated(
    ProfileNotificationSettingsUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    
    try {
      await _repository.updateProfile(
        field: 'popupNotifications',
        value: event.popupNotifications,
      );
      
      await _repository.updateProfile(
        field: 'emailNotifications',
        value: event.emailNotifications,
      );
      
      final data = await _repository.fetchProfileData();
      final profile = PatientProfileData.fromMap(data);
      
      emit(ProfileUpdateSuccess(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
      
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }
}