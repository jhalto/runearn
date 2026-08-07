import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class RecurringTransactionModel {
  const RecurringTransactionModel(this.data);
  final Map<String, dynamic> data;

  factory RecurringTransactionModel.fromEntity(
    RecurringTransaction item,
    String userId,
  ) => RecurringTransactionModel({
    'id': item.id,
    'userId': userId,
    'title': item.title,
    'amount': item.amount,
    'type': item.type.name,
    'category': item.category.value,
    'customCategory': item.customCategory,
    'accountId': item.accountId,
    'frequency': item.frequency.name,
    'nextDue': item.nextDue.toIso8601String(),
    'note': item.note,
    'isActive': item.isActive ? 1 : 0,
  });

  Map<String, dynamic> toMap() => data;

  RecurringTransaction toEntity() => RecurringTransaction(
    id: data['id'] as String,
    title: data['title'] as String,
    amount: (data['amount'] as num).toDouble(),
    type: TransactionType.values.firstWhere(
      (value) => value.name == data['type'],
      orElse: () => TransactionType.expense,
    ),
    category: TransactionCategoryX.fromValue(data['category'] as String),
    customCategory: data['customCategory'] as String?,
    accountId: data['accountId'] as String?,
    frequency: RecurrenceFrequency.values.firstWhere(
      (value) => value.name == data['frequency'],
      orElse: () => RecurrenceFrequency.monthly,
    ),
    nextDue: DateTime.parse(data['nextDue'] as String),
    note: data['note'] as String? ?? '',
    isActive: (data['isActive'] as num? ?? 1) == 1,
  );
}
