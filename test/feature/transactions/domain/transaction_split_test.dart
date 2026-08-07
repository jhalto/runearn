import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/services/budget_progress_calculator.dart';
import 'package:runearn/feature/reports/domain/services/financial_report_calculator.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';

void main() {
  final transaction = Transaction(
    id: 'split-1',
    amount: 1000,
    type: TransactionType.expense,
    category: TransactionCategory.other,
    description: 'Mixed purchase',
    date: DateTime(2026, 7, 10),
    splits: const [
      TransactionSplit(category: TransactionCategory.food, amount: 600),
      TransactionSplit(category: TransactionCategory.transport, amount: 400),
    ],
  );

  test('category analytics allocate without changing transaction total', () {
    final analytics = TransactionAnalytics([transaction]);

    expect(analytics.totalExpense, 1000);
    expect(analytics.byCategory(TransactionType.expense), {
      'Food': 600,
      'Transport': 400,
    });
  });

  test('budgets use only the matching split amount', () {
    final progress = BudgetProgressCalculator.calculate(
      [
        Budget(
          id: 'food',
          categoryName: 'Food',
          limit: 800,
          month: DateTime(2026, 7),
        ),
      ],
      [transaction],
      DateTime(2026, 7),
    );

    expect(progress.single.spent, 600);
  });

  test('reports preserve totals and allocate category insights', () {
    final report = FinancialReportCalculator.calculate(
      transactions: [transaction],
      endMonth: DateTime(2026, 7),
      monthCount: 1,
    );

    expect(report.periods.single.expense, 1000);
    expect(
      report.expenseCategories.map((item) => item.amount),
      containsAll([600, 400]),
    );
  });
}
