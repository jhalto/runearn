import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';
import 'package:runearn/feature/recurring/domain/services/recurrence_calculator.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

class RecurringRecordingService {
  const RecurringRecordingService({
    required this.recurring,
    required this.transactions,
  });

  final RecurringRepository recurring;
  final TransactionRepository transactions;

  Future<String> record(
    RecurringTransaction item, {
    DateTime? recordedAt,
  }) async {
    if (!item.isActive) throw StateError('This recurring item is paused');
    if (item.accountId == null) {
      throw StateError('Select an account before recording this item');
    }
    final now = recordedAt ?? DateTime.now();
    final transactionId = transactionIdFor(item);
    final transaction = Transaction(
      id: transactionId,
      amount: item.amount,
      type: item.type,
      category: item.category,
      customCategory: item.customCategory,
      accountId: item.accountId,
      description: item.note.isEmpty ? item.title : item.note,
      date: now,
    );

    await transactions.addTransaction(transaction);
    try {
      await recurring.save(
        item.copyWith(
          nextDue: RecurrenceCalculator.advancePast(
            item.nextDue,
            item.frequency,
            now,
          ),
        ),
      );
    } catch (_) {
      await transactions.deleteTransaction(transactionId);
      rethrow;
    }
    return transactionId;
  }

  static String transactionIdFor(RecurringTransaction item) =>
      'recurring_${item.id}_${item.nextDue.toUtc().millisecondsSinceEpoch}';
}
