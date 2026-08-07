import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';

abstract interface class RecurringRepository {
  Future<List<RecurringTransaction>> getRecurringTransactions();
  Future<void> save(RecurringTransaction item);
  Future<void> delete(String id);
  Future<void> syncPending();
}
