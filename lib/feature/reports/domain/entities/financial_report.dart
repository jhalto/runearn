import 'package:equatable/equatable.dart';

class ReportPeriod extends Equatable {
  const ReportPeriod({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
  double get cashFlow => income - expense;

  @override
  List<Object?> get props => [month, income, expense];
}

class CategoryInsight extends Equatable {
  const CategoryInsight({
    required this.name,
    required this.amount,
    required this.transactionCount,
  });

  final String name;
  final double amount;
  final int transactionCount;

  @override
  List<Object?> get props => [name, amount, transactionCount];
}

class FinancialReport extends Equatable {
  FinancialReport({
    required List<ReportPeriod> periods,
    required List<CategoryInsight> expenseCategories,
    required List<CategoryInsight> incomeCategories,
  }) : periods = List.unmodifiable(periods),
       expenseCategories = List.unmodifiable(expenseCategories),
       incomeCategories = List.unmodifiable(incomeCategories);

  final List<ReportPeriod> periods;
  final List<CategoryInsight> expenseCategories;
  final List<CategoryInsight> incomeCategories;

  double get totalIncome =>
      periods.fold(0, (total, period) => total + period.income);
  double get totalExpense =>
      periods.fold(0, (total, period) => total + period.expense);
  double get netCashFlow => totalIncome - totalExpense;
  double get savingsRate =>
      totalIncome <= 0 ? 0 : netCashFlow / totalIncome * 100;

  ReportPeriod? get currentPeriod => periods.isEmpty ? null : periods.last;
  ReportPeriod? get previousPeriod =>
      periods.length < 2 ? null : periods[periods.length - 2];

  double get expenseChangePercent {
    final current = currentPeriod;
    final previous = previousPeriod;
    if (current == null || previous == null || previous.expense == 0) return 0;
    return (current.expense - previous.expense) / previous.expense * 100;
  }

  @override
  List<Object?> get props => [periods, expenseCategories, incomeCategories];
}
