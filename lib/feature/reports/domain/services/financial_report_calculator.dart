import 'package:runearn/feature/reports/domain/entities/financial_report.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class FinancialReportCalculator {
  const FinancialReportCalculator._();

  static FinancialReport calculate({
    required Iterable<Transaction> transactions,
    required DateTime endMonth,
    required int monthCount,
    double Function(Transaction transaction)? amountInBase,
  }) {
    final convert = amountInBase ?? (transaction) => transaction.amount;
    if (monthCount <= 0) {
      throw ArgumentError.value(monthCount, 'monthCount', 'Must be positive');
    }
    final end = DateTime(endMonth.year, endMonth.month);
    final start = DateTime(end.year, end.month - monthCount + 1);
    final periods = List.generate(monthCount, (index) {
      final month = DateTime(start.year, start.month + index);
      var income = 0.0;
      var expense = 0.0;
      for (final transaction in transactions) {
        if (transaction.date.year != month.year ||
            transaction.date.month != month.month) {
          continue;
        }
        if (transaction.type == TransactionType.income) {
          income += convert(transaction);
        } else {
          expense += convert(transaction);
        }
      }
      return ReportPeriod(month: month, income: income, expense: expense);
    });

    final inRange = transactions.where((transaction) {
      final month = DateTime(transaction.date.year, transaction.date.month);
      return !month.isBefore(start) && !month.isAfter(end);
    });
    return FinancialReport(
      periods: periods,
      expenseCategories: _categories(inRange, TransactionType.expense, convert),
      incomeCategories: _categories(inRange, TransactionType.income, convert),
    );
  }

  static List<CategoryInsight> _categories(
    Iterable<Transaction> transactions,
    TransactionType type,
    double Function(Transaction transaction) convert,
  ) {
    final amounts = <String, double>{};
    final counts = <String, int>{};
    for (final transaction in transactions.where(
      (transaction) => transaction.type == type,
    )) {
      final convertedAmount = convert(transaction);
      for (final allocation in transaction.categoryAllocations) {
        final name = allocation.categoryName;
        final allocated = transaction.amount == 0
            ? 0.0
            : convertedAmount * (allocation.amount / transaction.amount);
        amounts.update(
          name,
          (amount) => amount + allocated,
          ifAbsent: () => allocated,
        );
        counts.update(name, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final result = amounts.entries
        .map(
          (entry) => CategoryInsight(
            name: entry.key,
            amount: entry.value,
            transactionCount: counts[entry.key] ?? 0,
          ),
        )
        .toList();
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }
}
