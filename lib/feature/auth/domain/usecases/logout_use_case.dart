import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _authRepository;

  const LogoutUseCase(this._authRepository);

  Future<void> call() {
    return _authRepository.logout();
  }
}
