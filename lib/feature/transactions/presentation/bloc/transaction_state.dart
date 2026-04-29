import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';

abstract class TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final TransactionAnalytics analytics;

  TransactionLoaded({
    required this.transactions,
    required this.analytics,
  });
}

class TransactionError extends TransactionState {
  final String message;

  TransactionError(this.message);
}