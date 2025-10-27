// lib/data/repositories/psychologist_repository_impl.dart

import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

class PsychologistRepositoryImpl implements PsychologistRepository {
  final PsychologistRemoteDataSource _remoteDataSource;

  PsychologistRepositoryImpl(this._remoteDataSource);

  // ================== INFORMACIÓN BÁSICA ==================

  @override
  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    try {
      print('📝 Repository: Actualizando información básica...');
      print('📋 UID: $uid');
      print('👤 Username: $username');
      print('📞 Teléfono: $phoneNumber');
      print('📸 Imagen: $profilePictureUrl');
      
      await _remoteDataSource.updateBasicInfo(
        uid: uid,
        username: username,
        phoneNumber: phoneNumber,
        profilePictureUrl: profilePictureUrl,
      );
      
      print('✅ Repository: Información básica actualizada exitosamente');
    } catch (e) {
      print('❌ Repository: Error actualizando información básica: $e');
      rethrow;
    }
  }

  // ================== INFORMACIÓN PROFESIONAL ==================

  @override
  Future<void> updateProfessionalInfo({
    required String uid,
    String? username,
    String? professionalLicense,
    String? professionalTitle,
    int? yearsExperience,
    String? description,
    List<String>? education,
    List<String>? certifications,
    String? specialty,
    List<String>? subSpecialties,
    Map<String, dynamic>? schedule,
    String? profilePictureUrl,
    bool? isAvailable,
    double? price,
  }) async {
    try {
      print('📝 Repository: Actualizando información profesional...');
      print('📋 UID: $uid');
      print('👤 Nombre completo: $username');
      print('🎓 Título: $professionalTitle');
      print('📄 Cédula: $professionalLicense');
      print('⏱️ Años experiencia: $yearsExperience');
      print('📝 Descripción: ${description?.substring(0, description.length > 50 ? 50 : description.length)}...');
      print('🎓 Educación: $education');
      print('📜 Certificaciones: $certifications');
      print('🏥 Especialidad: $specialty');
      print('🔹 Sub-especialidades: $subSpecialties');
      print('📅 Horario: $schedule');
      print('📸 Imagen URL: $profilePictureUrl');
      print('✅ Disponible: $isAvailable');
      print('💰 Precio: $price');
      
      await _remoteDataSource.updateProfessionalInfo(
        uid: uid,
        fullName: username,
        professionalLicense: professionalLicense,
        professionalTitle: professionalTitle,
        yearsExperience: yearsExperience,
        description: description,
        education: education,
        certifications: certifications,
        specialty: specialty,
        subSpecialties: subSpecialties,
        schedule: schedule,
        profilePictureUrl: profilePictureUrl,
        isAvailable: isAvailable,
        price: price,
      );
      
      print('✅ Repository: Información profesional actualizada exitosamente');
    } catch (e) {
      print('❌ Repository: Error actualizando información profesional: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // ================== OBTENER INFORMACIÓN ==================

  @override
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    try {
      print('🔍 Repository: Obteniendo psicólogo con UID: $uid');
      
      final psychologist = await _remoteDataSource.getPsychologistInfo(uid);
      
      if (psychologist != null) {
        print('✅ Repository: Psicólogo obtenido exitosamente');
        print('👤 Nombre: ${psychologist.fullName}');
        print('📧 Email: ${psychologist.email}');
        print('🎓 Título: ${psychologist.professionalTitle}');
        print('📄 Cédula: ${psychologist.professionalLicense}');
        print('⏱️ Años experiencia: ${psychologist.yearsExperience}');
        print('🏥 Especialidad: ${psychologist.specialty}');
        print('📸 Imagen: ${psychologist.profilePictureUrl}');
        print('💰 Precio: ${psychologist.price}');
        print('📅 Horario: ${psychologist.schedule}');
      } else {
        print('⚠️ Repository: Psicólogo no encontrado');
      }
      
      return psychologist;
    } catch (e) {
      print('❌ Repository: Error obteniendo psicólogo: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // ================== SUBIDA DE IMAGEN ==================
  
  @override
  Future<String> uploadProfilePicture(String imagePath) async {
    try {
      print('📤 Repository: Subiendo imagen de perfil...');
      print('📁 Ruta de la imagen: $imagePath');
      
      final url = await _remoteDataSource.uploadProfilePicture(imagePath);
      
      print('✅ Repository: Imagen subida exitosamente');
      print('🔗 URL de la imagen: $url');
      
      return url;
    } catch (e) {
      print('❌ Repository: Error subiendo imagen: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}