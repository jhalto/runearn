import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';

abstract class ProfileEvent {}

class LoadCurrentUserProfileEvent extends ProfileEvent {}

class ResetProfileEvent extends ProfileEvent {}

class CreateOrUpdateUserProfileEvent extends ProfileEvent {
  final User user;

  CreateOrUpdateUserProfileEvent(this.user);
}

class UpdateUserProfileEvent extends ProfileEvent {
  final UserEntity user;

  UpdateUserProfileEvent(this.user);
}
