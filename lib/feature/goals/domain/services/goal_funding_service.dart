import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/repositories/account_repository.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';
import 'package:runearn/feature/goals/domain/repositories/goal_repository.dart';

class GoalFundingService {
  const GoalFundingService({required this.goals, required this.accounts});

  final GoalRepository goals;
  final AccountRepository accounts;

  Future<void> contribute({
    required FinancialGoal goal,
    required GoalContribution contribution,
  }) async {
    final sourceId = contribution.sourceAccountId;
    final goalAccountId = contribution.goalAccountId;
    final transferId = contribution.transferId;
    if (sourceId == null || goalAccountId == null || transferId == null) {
      throw ArgumentError('A funding account is required');
    }
    if (contribution.amount <= 0) {
      throw ArgumentError('Contribution amount must be greater than zero');
    }

    final allAccounts = await accounts.getAccounts();
    final source = allAccounts.cast<FinanceAccount?>().firstWhere(
      (account) => account!.id == sourceId,
      orElse: () => null,
    );
    if (source == null) throw StateError('Funding account no longer exists');
    if (source.type.classification != AccountClassification.asset) {
      throw StateError('Choose an asset account to fund this goal');
    }

    final existingGoalAccount = allAccounts.cast<FinanceAccount?>().firstWhere(
      (account) => account!.id == goalAccountId,
      orElse: () => null,
    );
    if (existingGoalAccount != null &&
        existingGoalAccount.currencyCode != source.currencyCode) {
      throw StateError(
        'Choose a ${existingGoalAccount.currencyCode} funding account',
      );
    }
    if (existingGoalAccount == null) {
      await accounts.saveAccount(
        FinanceAccount(
          id: goalAccountId,
          name: '${goal.name} savings',
          type: FinanceAccountType.savings,
          balance: 0,
          createdAt: contribution.date,
          currencyCode: source.currencyCode,
          note: 'Dedicated account for goal ${goal.id}',
        ),
      );
    }

    await accounts.saveTransfer(
      AccountTransfer(
        id: transferId,
        fromAccountId: sourceId,
        toAccountId: goalAccountId,
        amount: contribution.amount,
        date: contribution.date,
        note: 'Goal contribution: ${goal.name}',
      ),
    );
    try {
      await goals.saveContribution(contribution);
    } catch (_) {
      await accounts.deleteTransfer(transferId);
      rethrow;
    }
  }

  Future<void> deleteContribution(GoalContribution contribution) async {
    final transferId = contribution.transferId;
    if (transferId != null) await accounts.deleteTransfer(transferId);
    await goals.deleteContribution(contribution.id);
  }

  Future<void> deleteGoal(String goalId) async {
    final contributions = await goals.getContributions();
    for (final contribution in contributions.where(
      (item) => item.goalId == goalId,
    )) {
      final transferId = contribution.transferId;
      if (transferId != null) await accounts.deleteTransfer(transferId);
    }
    await goals.deleteGoal(goalId);
  }
}
