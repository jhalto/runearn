import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';

class AccountTransferModel {
  const AccountTransferModel({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.receivedAmount,
    required this.date,
    required this.note,
  });

  final String id;
  final String userId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final double receivedAmount;
  final String date;
  final String note;

  factory AccountTransferModel.fromEntity(
    AccountTransfer transfer, {
    required String userId,
  }) => AccountTransferModel(
    id: transfer.id,
    userId: userId,
    fromAccountId: transfer.fromAccountId,
    toAccountId: transfer.toAccountId,
    amount: transfer.amount,
    receivedAmount: transfer.receivedAmount,
    date: transfer.date.toIso8601String(),
    note: transfer.note,
  );

  factory AccountTransferModel.fromMap(Map<String, dynamic> map) =>
      AccountTransferModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        fromAccountId: map['fromAccountId'] as String,
        toAccountId: map['toAccountId'] as String,
        amount: (map['amount'] as num).toDouble(),
        receivedAmount:
            (map['receivedAmount'] as num?)?.toDouble() ??
            (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
    'amount': amount,
    'receivedAmount': receivedAmount,
    'date': date,
    'note': note,
  };

  AccountTransfer toEntity() => AccountTransfer(
    id: id,
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    amount: amount,
    receivedAmount: receivedAmount,
    date: DateTime.parse(date),
    note: note,
  );
}
