import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/entities/budget_progress.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class BudgetProgressCalculator {
  const BudgetProgressCalculator._();

  static List<BudgetProgress> calculate(
    Iterable<Budget> budgets,
    Iterable<Transaction> transactions,
    DateTime month,
  ) {
    final active = budgets.where((budget) => !budget.isTemplate).toList();
    final selected = active.where(
      (budget) =>
          budget.month.year == month.year && budget.month.month == month.month,
    );
    return selected
        .map((budget) {
          var spent = 0.0;
          for (final transaction in transactions) {
            if (transaction.type != TransactionType.expense ||
                transaction.date.year != month.year ||
                transaction.date.month != month.month) {
              continue;
            }
            for (final allocation in transaction.categoryAllocations) {
              if (allocation.categoryName.toLowerCase() ==
                  budget.categoryName.toLowerCase()) {
                spent += allocation.amount;
              }
            }
          }
          final previousMonth = DateTime(month.year, month.month - 1);
          final previous = active.cast<Budget?>().firstWhere(
            (candidate) =>
                candidate!.categoryName.toLowerCase() ==
                    budget.categoryName.toLowerCase() &&
                candidate.month.year == previousMonth.year &&
                candidate.month.month == previousMonth.month,
            orElse: () => null,
          );
          var rolledOver = 0.0;
          if (budget.rolloverEnabled && previous != null) {
            final previousSpent = _spentFor(
              previous,
              transactions,
              previousMonth,
            );
            rolledOver = (previous.limit - previousSpent).clamp(
              0,
              double.infinity,
            );
          }
          return BudgetProgress(
            budget: budget,
            spent: spent,
            effectiveLimit: budget.limit + rolledOver,
            rolledOver: rolledOver,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => b.ratio.compareTo(a.ratio));
  }

  static double _spentFor(
    Budget budget,
    Iterable<Transaction> transactions,
    DateTime month,
  ) {
    var spent = 0.0;
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense ||
          transaction.date.year != month.year ||
          transaction.date.month != month.month) {
        continue;
      }
      for (final allocation in transaction.categoryAllocations) {
        if (allocation.categoryName.toLowerCase() ==
            budget.categoryName.toLowerCase()) {
          spent += allocation.amount;
        }
      }
    }
    return spent;
  }
}
