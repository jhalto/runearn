import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:runearn/config/firebase/firebase_config.dart';
import 'package:runearn/feature/profile/data/services/local_account_data_purger.dart';
import 'package:runearn/feature/profile/domain/repositories/account_deletion_repository.dart';

class AccountDeletionService implements AccountDeletionRepository {
  const AccountDeletionService({
    required this.auth,
    required this.firestore,
    required this.localPurger,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final LocalAccountDataPurger localPurger;

  @override
  Future<void> deleteCurrentAccount({String? password}) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('No authenticated account was found.');

    await _reauthenticate(user, password: password);
    final userId = user.uid;
    await _deleteRemoteData(userId);
    await user.delete();
    await localPurger.purge(userId);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<void> _reauthenticate(User user, {String? password}) async {
    if (user.isAnonymous) return;
    final providers = user.providerData.map((item) => item.providerId).toSet();

    if (providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw const AccountDeletionException(
          'Enter your password to verify this deletion.',
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }

    if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      final google = GoogleSignIn.instance;
      await google.initialize(serverClientId: FirebaseConfig.googleWebClientId);
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AccountDeletionException(
          'Google could not verify this account. Please try again.',
        );
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      return;
    }

    throw const AccountDeletionException(
      'This sign-in provider cannot be verified in the app.',
    );
  }

  Future<void> _deleteRemoteData(String userId) async {
    final user = firestore.collection('users').doc(userId);
    final tours = await user
        .collection('tours')
        .get(const GetOptions(source: Source.server));
    for (final tour in tours.docs) {
      await _deleteCollection(tour.reference.collection('collections'));
      await _deleteCollection(tour.reference.collection('expenses'));
    }

    for (final name in const [
      'transactions',
      'accounts',
      'accountTransfers',
      'budgets',
      'goals',
      'goalContributions',
      'recurringTransactions',
      'loans',
      'loanPayments',
      'tourCollections',
      'tourExpenses',
      'auditLogs',
      'tours',
    ]) {
      await _deleteCollection(user.collection(name));
    }
    await user.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection
          .limit(400)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      final batch = firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);
  final String message;

  @override
  String toString() => message;
}
