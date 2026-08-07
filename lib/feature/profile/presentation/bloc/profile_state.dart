import 'package:runearn/feature/profile/domain/entities/user_entity.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;

  ProfileLoaded(this.user);
}

class ProfileEmpty extends ProfileState {}

class ProfileFailure extends ProfileState {
  final String message;

  ProfileFailure(this.message);
}