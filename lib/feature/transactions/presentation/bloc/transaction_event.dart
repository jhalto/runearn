import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadTransactions extends TransactionEvent {
  const LoadTransactions();
}

final class ResetTransactions extends TransactionEvent {
  const ResetTransactions();
}

final class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class UpdateTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

final class DeleteTransactionEvent extends TransactionEvent {
  final String id;

  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

final class SyncPendingTransactionsEvent extends TransactionEvent {
  const SyncPendingTransactionsEvent();
}
