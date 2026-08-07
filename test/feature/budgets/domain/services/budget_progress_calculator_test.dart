import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/services/budget_progress_calculator.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

void main() {
  test('counts only matching expenses in the selected month', () {
    final budget = Budget(
      id: 'food-budget',
      categoryName: 'Food',
      limit: 1000,
      month: DateTime(2026, 7),
    );
    final transactions = [
      Transaction(
        id: 'expense',
        amount: 800,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        description: '',
        date: DateTime(2026, 7, 10),
      ),
      Transaction(
        id: 'income',
        amount: 500,
        type: TransactionType.income,
        category: TransactionCategory.food,
        description: '',
        date: DateTime(2026, 7, 11),
      ),
      Transaction(
        id: 'other-month',
        amount: 300,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        description: '',
        date: DateTime(2026, 8),
      ),
    ];

    final progress = BudgetProgressCalculator.calculate(
      [budget],
      transactions,
      DateTime(2026, 7),
    ).single;

    expect(progress.spent, 800);
    expect(progress.remaining, 200);
    expect(progress.ratio, .8);
    expect(progress.isOverBudget, isFalse);
  });

  test('matches custom categories without case sensitivity', () {
    final progress = BudgetProgressCalculator.calculate(
      [
        Budget(
          id: 'custom',
          categoryName: 'Baby Care',
          limit: 200,
          month: DateTime(2026, 7),
        ),
      ],
      [
        Transaction(
          id: 'expense',
          amount: 250,
          type: TransactionType.expense,
          category: TransactionCategory.other,
          customCategory: 'baby care',
          description: '',
          date: DateTime(2026, 7),
        ),
      ],
      DateTime(2026, 7),
    ).single;

    expect(progress.spent, 250);
    expect(progress.isOverBudget, isTrue);
  });

  test('rolls the previous month unused amount into the selected month', () {
    final progress = BudgetProgressCalculator.calculate(
      [
        Budget(
          id: 'june',
          categoryName: 'Food',
          limit: 1000,
          month: DateTime(2026, 6),
        ),
        Budget(
          id: 'july',
          categoryName: 'Food',
          limit: 1200,
          month: DateTime(2026, 7),
          rolloverEnabled: true,
        ),
      ],
      [
        Transaction(
          id: 'june-expense',
          amount: 700,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          description: '',
          date: DateTime(2026, 6, 10),
        ),
      ],
      DateTime(2026, 7),
    ).single;

    expect(progress.rolledOver, 300);
    expect(progress.effectiveLimit, 1500);
    expect(progress.remaining, 1500);
  });

  test('does not include reusable templates in monthly progress', () {
    final progress = BudgetProgressCalculator.calculate(
      [
        Budget(
          id: 'template',
          categoryName: 'Food',
          limit: 1000,
          month: DateTime(2026, 7),
          isTemplate: true,
          templateName: 'Essentials',
        ),
      ],
      const [],
      DateTime(2026, 7),
    );

    expect(progress, isEmpty);
  });
}
