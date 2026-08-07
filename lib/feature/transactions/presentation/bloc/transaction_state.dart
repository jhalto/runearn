import 'package:equatable/equatable.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => const [];
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final TransactionAnalytics analytics;

  TransactionLoaded({
    required List<Transaction> transactions,
    required this.analytics,
  }) : transactions = List.unmodifiable(transactions);

  @override
  List<Object?> get props => [transactions];
}

final class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

final class TransactionSyncing extends TransactionState {
  final List<Transaction> transactions;
  final TransactionAnalytics analytics;

  TransactionSyncing({
    required List<Transaction> transactions,
    required this.analytics,
  }) : transactions = List.unmodifiable(transactions);

  @override
  List<Object?> get props => [transactions];
}
