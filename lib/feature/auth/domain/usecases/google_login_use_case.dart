import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository _authRepository;

  const GoogleLoginUseCase(this._authRepository);

  Future<UserCredential> call() {
    return _authRepository.loginWithGoogle();
  }
}