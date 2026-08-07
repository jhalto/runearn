import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  final TransactionRepository repository;

  const UpdateTransactionUseCase(this.repository);

  Future<void> call(Transaction transaction) {
    return repository.updateTransaction(transaction);
  }
}
