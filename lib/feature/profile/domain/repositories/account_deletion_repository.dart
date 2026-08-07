abstract interface class AccountDeletionRepository {
  Future<void> deleteCurrentAccount({String? password});
}
