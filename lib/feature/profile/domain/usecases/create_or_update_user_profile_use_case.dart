import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';

import 'package:runearn/feature/profile/domain/repositories/profile_repository.dart';

class CreateOrUpdateUserProfileUseCase {
  final ProfileRepository repository;

  const CreateOrUpdateUserProfileUseCase(this.repository);

  Future<UserEntity> call(User user) {
    return repository.createOrUpdateUserProfile(user);
  }
}