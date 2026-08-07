import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class SyncPendingTransactionsUseCase {
  final TransactionRepository repository;

  SyncPendingTransactionsUseCase(this.repository);

  Future<void> call() {
    return repository.syncPendingTransactions();
  }
}
