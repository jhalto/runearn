import 'package:equatable/equatable.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';

class BudgetProgress extends Equatable {
  BudgetProgress({
    required this.budget,
    required this.spent,
    double? effectiveLimit,
    this.rolledOver = 0,
  }) : effectiveLimit = effectiveLimit ?? budget.limit;

  final Budget budget;
  final double spent;
  final double effectiveLimit;
  final double rolledOver;

  double get remaining => effectiveLimit - spent;
  double get ratio => effectiveLimit <= 0 ? 0 : spent / effectiveLimit;
  bool get isOverBudget => spent > effectiveLimit;

  @override
  List<Object?> get props => [budget, spent, effectiveLimit, rolledOver];
}
