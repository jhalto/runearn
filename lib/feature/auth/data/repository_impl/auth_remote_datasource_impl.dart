import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:runearn/config/firebase/firebase_config.dart';
import 'package:runearn/feature/auth/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<UserCredential> loginWithEmailPassword(
    LoginCredentialEntity credential,
  ) {
    return firebaseAuth.signInWithEmailAndPassword(
      email: credential.email,
      password: credential.password,
    );
  }

  @override
  Future<UserCredential> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: FirebaseConfig.googleWebClientId,
    );

    try {
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google ID token not found.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      return firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.description ?? e.toString(),
      );
    }
  }

  @override
  Future<UserCredential> loginAsGuest() {
    return firebaseAuth.signInAnonymously();
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  @override
  User? getCurrentUser() {
    return firebaseAuth.currentUser;
  }

  @override
  Future<UserCredential> registerWithEmailPassword(
    LoginCredentialEntity credential,
  ) {
    return firebaseAuth.createUserWithEmailAndPassword(
      email: credential.email,
      password: credential.password,
    );
  }
}
