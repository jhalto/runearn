import 'package:equatable/equatable.dart';

class AccountTransfer extends Equatable {
  const AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    double? receivedAmount,
    required this.date,
    this.note = '',
  }) : receivedAmount = receivedAmount ?? amount;

  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final double receivedAmount;
  final DateTime date;
  final String note;

  @override
  List<Object?> get props => [
    id,
    fromAccountId,
    toAccountId,
    amount,
    receivedAmount,
    date,
    note,
  ];
}
