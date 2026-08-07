import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  const LoginUseCase(this._authRepository);

  Future<UserCredential> call(LoginCredentialEntity credential) {
    return _authRepository.loginWithEmailPassword(credential);
  }
}