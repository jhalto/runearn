import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class GuestLoginUseCase {
  final AuthRepository _authRepository;

  const GuestLoginUseCase(this._authRepository);

  Future<UserCredential> call() {
    return _authRepository.loginAsGuest();
  }
}