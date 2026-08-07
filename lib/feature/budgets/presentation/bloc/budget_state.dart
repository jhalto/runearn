import 'package:equatable/equatable.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';

sealed class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => const [];
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

final class BudgetLoaded extends BudgetState {
  BudgetLoaded(List<Budget> budgets) : budgets = List.unmodifiable(budgets);
  final List<Budget> budgets;
  @override
  List<Object?> get props => [budgets];
}

final class BudgetFailure extends BudgetState {
  const BudgetFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
