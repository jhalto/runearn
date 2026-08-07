import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';
import 'package:runearn/feature/recurring/domain/services/recurring_recording_service.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';

void main() {
  final item = RecurringTransaction(
    id: 'rent',
    title: 'Rent',
    amount: 1200,
    type: TransactionType.expense,
    category: TransactionCategory.rent,
    accountId: 'bank',
    frequency: RecurrenceFrequency.monthly,
    nextDue: DateTime(2026, 7, 1),
  );

  test('records transaction before advancing the schedule', () async {
    final recurring = _RecurringRepository();
    final transactions = _TransactionRepository();
    final service = RecurringRecordingService(
      recurring: recurring,
      transactions: transactions,
    );

    final id = await service.record(item, recordedAt: DateTime(2026, 7, 1));

    expect(id, RecurringRecordingService.transactionIdFor(item));
    expect(transactions.saved.single.id, id);
    expect(recurring.saved.single.nextDue, DateTime(2026, 8, 1));
  });

  test('removes generated transaction when schedule update fails', () async {
    final recurring = _RecurringRepository(failSave: true);
    final transactions = _TransactionRepository();
    final service = RecurringRecordingService(
      recurring: recurring,
      transactions: transactions,
    );

    await expectLater(
      service.record(item, recordedAt: DateTime(2026, 7, 1)),
      throwsStateError,
    );

    expect(transactions.deleted, [
      RecurringRecordingService.transactionIdFor(item),
    ]);
  });
}

class _RecurringRepository implements RecurringRepository {
  _RecurringRepository({this.failSave = false});
  final bool failSave;
  final List<RecurringTransaction> saved = [];

  @override
  Future<void> save(RecurringTransaction item) async {
    if (failSave) throw StateError('save failed');
    saved.add(item);
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async => saved;
  @override
  Future<void> syncPending() async {}
}

class _TransactionRepository implements TransactionRepository {
  final List<Transaction> saved = [];
  final List<String> deleted = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    saved.removeWhere((item) => item.id == transaction.id);
    saved.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async => deleted.add(id);
  @override
  Future<List<Transaction>> getTransactions() async => saved;
  @override
  Future<void> updateTransaction(Transaction transaction) async {}
  @override
  Future<void> syncPendingTransactions() async {}
  @override
  Future<void> clearTransactions({TransactionType? type}) async {}
}
