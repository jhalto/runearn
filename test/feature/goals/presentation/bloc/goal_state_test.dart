import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_state.dart';

void main() {
  test('calculates saved amount, progress, and completion', () {
    final goal = FinancialGoal(
      id: 'emergency',
      name: 'Emergency fund',
      targetAmount: 10000,
      createdAt: DateTime(2026),
    );
    final state = GoalLoaded(
      [goal],
      [
        GoalContribution(
          id: 'one',
          goalId: goal.id,
          amount: 4000,
          date: DateTime(2026),
        ),
        GoalContribution(
          id: 'two',
          goalId: goal.id,
          amount: 6000,
          date: DateTime(2026, 2),
        ),
      ],
    );

    expect(state.savedFor(goal.id), 10000);
    expect(state.progressFor(goal), 1);
    expect(state.isCompleted(goal), isTrue);
  });

  test('does not include contributions from another goal', () {
    final goal = FinancialGoal(
      id: 'travel',
      name: 'Travel',
      targetAmount: 5000,
      createdAt: DateTime(2026),
    );
    final state = GoalLoaded(
      [goal],
      [
        GoalContribution(
          id: 'other',
          goalId: 'different-goal',
          amount: 2000,
          date: DateTime(2026),
        ),
      ],
    );

    expect(state.savedFor(goal.id), 0);
    expect(state.isCompleted(goal), isFalse);
  });
}
