import 'package:runearn/feature/profile/domain/entities/user_entity.dart';
import 'package:runearn/feature/profile/domain/repositories/profile_repository.dart';

class GetCurrentUserProfileUseCase {
  final ProfileRepository repository;

  const GetCurrentUserProfileUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUserProfile();
  }
}