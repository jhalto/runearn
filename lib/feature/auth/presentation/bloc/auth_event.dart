import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';

abstract class AuthEvent {}

class LoginWithEmailPasswordEvent extends AuthEvent {
  final LoginCredentialEntity credential;

  LoginWithEmailPasswordEvent({required this.credential});
}

class LoginWithGoogleEvent extends AuthEvent {}

class LoginAsGuestEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class AccountDeletedEvent extends AuthEvent {}

class RegisterWithEmailPasswordEvent extends AuthEvent {
  final LoginCredentialEntity credential;

  RegisterWithEmailPasswordEvent({required this.credential});
}
