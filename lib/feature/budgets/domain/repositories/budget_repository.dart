import 'package:runearn/feature/budgets/domain/entities/budget.dart';

abstract interface class BudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<void> saveBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> syncPending();
}
