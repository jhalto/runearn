import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/reports/domain/services/financial_report_calculator.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

void main() {
  test('calculates period totals, cash flow, and savings rate', () {
    final report = FinancialReportCalculator.calculate(
      endMonth: DateTime(2026, 7),
      monthCount: 2,
      transactions: [
        _transaction(
          id: 'income',
          amount: 10000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 7),
        ),
        _transaction(
          id: 'food',
          amount: 3000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 7),
        ),
        _transaction(
          id: 'old',
          amount: 2000,
          type: TransactionType.expense,
          category: TransactionCategory.rent,
          date: DateTime(2026, 5),
        ),
      ],
    );

    expect(report.totalIncome, 10000);
    expect(report.totalExpense, 3000);
    expect(report.netCashFlow, 7000);
    expect(report.savingsRate, 70);
    expect(report.expenseCategories.single.name, 'Food');
  });

  test('groups custom categories and sorts them by amount', () {
    final report = FinancialReportCalculator.calculate(
      endMonth: DateTime(2026, 7),
      monthCount: 1,
      transactions: [
        _transaction(
          id: 'one',
          amount: 500,
          type: TransactionType.expense,
          category: TransactionCategory.other,
          customCategory: 'Baby Care',
          date: DateTime(2026, 7),
        ),
        _transaction(
          id: 'two',
          amount: 100,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 7),
        ),
      ],
    );

    expect(report.expenseCategories.first.name, 'Baby Care');
    expect(report.expenseCategories.first.amount, 500);
  });
}

Transaction _transaction({
  required String id,
  required double amount,
  required TransactionType type,
  required TransactionCategory category,
  required DateTime date,
  String? customCategory,
}) => Transaction(
  id: id,
  amount: amount,
  type: type,
  category: category,
  customCategory: customCategory,
  description: '',
  date: date,
);
