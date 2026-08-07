import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:runearn/config/firebase/firebase_config.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> loginWithEmailPassword(
    LoginCredentialEntity credential,
  );

  Future<UserCredential> loginWithGoogle();

  Future<UserCredential> loginAsGuest();

  Future<void> logout();

  User? getCurrentUser();
  Future<UserCredential> registerWithEmailPassword(
    LoginCredentialEntity credential,
  );
}
