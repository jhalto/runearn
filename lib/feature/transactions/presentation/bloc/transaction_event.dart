import '../../domain/entities/transaction.dart';

abstract class TransactionEvent {}

class LoadTransactions extends TransactionEvent {}

class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  AddTransactionEvent(this.transaction);
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;

  DeleteTransactionEvent(this.id);
}

class UpdateTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  UpdateTransactionEvent(this.transaction);
}
