import 'package:equatable/equatable.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';

sealed class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => const [];
}

final class LoadGoals extends GoalEvent {
  const LoadGoals();
}

final class SaveGoalRequested extends GoalEvent {
  const SaveGoalRequested(this.goal);
  final FinancialGoal goal;
  @override
  List<Object?> get props => [goal];
}

final class DeleteGoalRequested extends GoalEvent {
  const DeleteGoalRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class AddGoalContributionRequested extends GoalEvent {
  const AddGoalContributionRequested(this.goal, this.contribution);
  final FinancialGoal goal;
  final GoalContribution contribution;
  @override
  List<Object?> get props => [goal, contribution];
}

final class DeleteGoalContributionRequested extends GoalEvent {
  const DeleteGoalContributionRequested(this.contribution);
  final GoalContribution contribution;
  @override
  List<Object?> get props => [contribution];
}

final class SyncGoalsRequested extends GoalEvent {
  const SyncGoalsRequested();
}

final class ResetGoals extends GoalEvent {
  const ResetGoals();
}
