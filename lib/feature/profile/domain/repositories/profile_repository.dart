import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';


abstract class ProfileRepository {
  Future<UserEntity> createOrUpdateUserProfile(User user);

  Future<UserEntity?> getCurrentUserProfile();

  Future<void> updateUserProfile(UserEntity user);
}