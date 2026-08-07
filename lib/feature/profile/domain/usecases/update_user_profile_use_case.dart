import 'package:runearn/feature/profile/domain/entities/user_entity.dart';
import 'package:runearn/feature/profile/domain/repositories/profile_repository.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository repository;

  const UpdateUserProfileUseCase(this.repository);

  Future<void> call(UserEntity user) {
    return repository.updateUserProfile(user);
  }
}