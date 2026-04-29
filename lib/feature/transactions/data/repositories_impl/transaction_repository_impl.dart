import 'package:runearn/feature/transactions/data/datasources/transaction_db.dart';
import 'package:runearn/feature/transactions/data/models/transaction_model.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async {
    final data = await TransactionDB.getTransactions();

    return data.map((e) => TransactionModel.fromMap(e).toEntity()).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);

    await TransactionDB.insertTransaction(model.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await TransactionDB.deleteTransaction(id);
  }
}
