import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/auth/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserCredential> loginWithEmailPassword(
    LoginCredentialEntity credential,
  ) {
    return remoteDataSource.loginWithEmailPassword(credential);
  }

  @override
  Future<UserCredential> loginWithGoogle() {
    return remoteDataSource.loginWithGoogle();
  }

  @override
  Future<UserCredential> loginAsGuest() {
    return remoteDataSource.loginAsGuest();
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  User? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<UserCredential> registerWithEmailPassword(
    LoginCredentialEntity credential,
  ) {
    return remoteDataSource.registerWithEmailPassword(credential);
  }
}
