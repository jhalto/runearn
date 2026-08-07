import 'package:equatable/equatable.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => const [];
}

final class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
}

final class SaveBudgetRequested extends BudgetEvent {
  const SaveBudgetRequested(this.budget);
  final Budget budget;
  @override
  List<Object?> get props => [budget];
}

final class DeleteBudgetRequested extends BudgetEvent {
  const DeleteBudgetRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class SyncBudgetsRequested extends BudgetEvent {
  const SyncBudgetsRequested();
}

final class ResetBudgets extends BudgetEvent {
  const ResetBudgets();
}
