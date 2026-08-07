import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/dashboard/domain/services/financial_health_calculator.dart';

void main() {
  test('rewards positive cash flow and low liabilities', () {
    final report = FinancialHealthCalculator.calculate(
      monthlyIncome: 10000,
      monthlyExpense: 7000,
      assets: 100000,
      liabilities: 10000,
      budgetLimit: 8000,
      budgetSpent: 7000,
      overdueObligations: 0,
    );

    expect(report.score, greaterThanOrEqualTo(75));
    expect(report.indicators, hasLength(5));
    expect(report.label, anyOf('Stable', 'Strong'));
  });

  test('returns actionable recommendations for financial risks', () {
    final report = FinancialHealthCalculator.calculate(
      monthlyIncome: 5000,
      monthlyExpense: 6000,
      assets: 1000,
      liabilities: 8000,
      budgetLimit: 0,
      budgetSpent: 0,
      overdueObligations: 2,
    );

    expect(report.score, lessThan(40));
    expect(report.recommendations, isNotEmpty);
    expect(
      report.recommendations.any((item) => item.contains('overdue')),
      isTrue,
    );
  });

  test('score remains within the documented zero to one hundred range', () {
    final report = FinancialHealthCalculator.calculate(
      monthlyIncome: 0,
      monthlyExpense: 0,
      assets: 0,
      liabilities: 0,
      budgetLimit: 0,
      budgetSpent: 0,
      overdueObligations: 100,
    );

    expect(report.score, inInclusiveRange(0, 100));
  });
}
