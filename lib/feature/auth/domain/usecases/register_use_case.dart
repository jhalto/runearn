import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserCredential> call(LoginCredentialEntity credential) {
    return repository.registerWithEmailPassword(credential);
  }
}