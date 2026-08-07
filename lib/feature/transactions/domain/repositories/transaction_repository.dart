import '../entities/transaction.dart';
import '../entities/transaction_type.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();

  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> syncPendingTransactions();
  Future<void> clearTransactions({TransactionType? type});
}
