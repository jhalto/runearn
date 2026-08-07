import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';

abstract interface class GoalRepository {
  Future<List<FinancialGoal>> getGoals();
  Future<List<GoalContribution>> getContributions();
  Future<void> saveGoal(FinancialGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> saveContribution(GoalContribution contribution);
  Future<void> deleteContribution(String id);
  Future<void> syncPending();
}
