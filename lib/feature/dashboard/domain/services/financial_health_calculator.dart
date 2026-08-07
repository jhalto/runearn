import 'dart:math' as math;

import 'package:runearn/feature/dashboard/domain/entities/financial_health_report.dart';

class FinancialHealthCalculator {
  const FinancialHealthCalculator._();

  static FinancialHealthReport calculate({
    required double monthlyIncome,
    required double monthlyExpense,
    required double assets,
    required double liabilities,
    required double budgetLimit,
    required double budgetSpent,
    required int overdueObligations,
  }) {
    final savingsRate = monthlyIncome <= 0
        ? 0.0
        : (monthlyIncome - monthlyExpense) / monthlyIncome;
    final cashFlowScore = (savingsRate.clamp(0, .25) / .25 * 25).round();
    final debtRatio = assets <= 0
        ? (liabilities > 0 ? 1.0 : 0.0)
        : liabilities / assets;
    final debtScore = ((1 - debtRatio.clamp(0, 1)) * 25).round();
    final budgetRatio = budgetLimit <= 0 ? 1.0 : budgetSpent / budgetLimit;
    final budgetScore = budgetLimit <= 0
        ? 10
        : ((1 - (budgetRatio - .75).clamp(0, .75) / .75) * 20).round();
    final reserveMonths = monthlyExpense <= 0
        ? (assets > 0 ? 6.0 : 0.0)
        : assets / monthlyExpense;
    final reserveScore = (reserveMonths.clamp(0, 6) / 6 * 20).round();
    final obligationScore = math.max(0, 10 - overdueObligations * 3);

    final indicators = [
      FinancialHealthIndicator(
        label: 'Cash flow',
        score: cashFlowScore,
        maximum: 25,
        detail: monthlyIncome <= 0
            ? 'No income recorded this month'
            : '${(savingsRate * 100).toStringAsFixed(0)}% savings rate',
      ),
      FinancialHealthIndicator(
        label: 'Debt position',
        score: debtScore,
        maximum: 25,
        detail: '${(debtRatio * 100).toStringAsFixed(0)}% debt-to-assets',
      ),
      FinancialHealthIndicator(
        label: 'Budget control',
        score: budgetScore,
        maximum: 20,
        detail: budgetLimit <= 0
            ? 'No monthly budget configured'
            : '${(budgetRatio * 100).toStringAsFixed(0)}% used',
      ),
      FinancialHealthIndicator(
        label: 'Asset coverage',
        score: reserveScore,
        maximum: 20,
        detail: '${reserveMonths.toStringAsFixed(1)} months of expenses',
      ),
      FinancialHealthIndicator(
        label: 'Payment status',
        score: obligationScore,
        maximum: 10,
        detail: overdueObligations == 0
            ? 'No overdue obligations'
            : '$overdueObligations overdue',
      ),
    ];
    final recommendations = <String>[
      if (savingsRate < .1)
        'Aim to keep at least 10% of monthly income after expenses.',
      if (debtRatio > .5)
        'Prioritize high-cost liabilities to improve your debt position.',
      if (budgetLimit <= 0)
        'Create category budgets to make spending performance measurable.'
      else if (budgetRatio > 1)
        'Review categories that exceeded their monthly limits.',
      if (reserveMonths < 3)
        'Build liquid emergency savings covering at least three months.',
      if (overdueObligations > 0)
        'Resolve overdue bills and recurring payments first.',
    ];
    return FinancialHealthReport(
      score: indicators.fold(0, (total, item) => total + item.score),
      indicators: List.unmodifiable(indicators),
      recommendations: List.unmodifiable(recommendations),
    );
  }
}
