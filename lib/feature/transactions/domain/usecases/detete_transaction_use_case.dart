import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  const DeleteTransactionUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteTransaction(id);
  }
}
