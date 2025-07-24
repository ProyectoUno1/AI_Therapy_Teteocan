// lib/domain/usecases/user/get_user_role_usecase.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/user_repository.dart';

class GetUserRoleUseCase {
  final UserRepository repository;

  GetUserRoleUseCase(this.repository);

  Future<UserEntity> call(String uid) {
    return repository.getUserRoleAndData(uid);
  }
}
