import 'package:equatable/equatable.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';

sealed class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => const [];
}

final class GoalInitial extends GoalState {
  const GoalInitial();
}

final class GoalLoading extends GoalState {
  const GoalLoading();
}

final class GoalLoaded extends GoalState {
  GoalLoaded(List<FinancialGoal> goals, List<GoalContribution> contributions)
    : goals = List.unmodifiable(goals),
      contributions = List.unmodifiable(contributions);

  final List<FinancialGoal> goals;
  final List<GoalContribution> contributions;

  List<GoalContribution> contributionsFor(String goalId) => contributions
      .where((item) => item.goalId == goalId)
      .toList(growable: false);

  double savedFor(String goalId) => contributions
      .where((item) => item.goalId == goalId)
      .fold(0, (total, item) => total + item.amount);

  double progressFor(FinancialGoal goal) =>
      goal.targetAmount <= 0 ? 0 : savedFor(goal.id) / goal.targetAmount;

  bool isCompleted(FinancialGoal goal) =>
      savedFor(goal.id) >= goal.targetAmount;

  @override
  List<Object?> get props => [goals, contributions];
}

final class GoalFailure extends GoalState {
  const GoalFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
