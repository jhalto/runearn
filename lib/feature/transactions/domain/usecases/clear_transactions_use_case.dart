import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class ClearTransactionsUseCase {
  final TransactionRepository repository;

  const ClearTransactionsUseCase(this.repository);

  Future<void> call({TransactionType? type}) {
    return repository.clearTransactions(type: type);
  }
}
