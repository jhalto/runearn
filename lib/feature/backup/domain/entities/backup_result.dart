import 'package:equatable/equatable.dart';

class BackupResult extends Equatable {
  const BackupResult({
    required this.accounts,
    required this.transfers,
    required this.transactions,
    required this.loans,
    required this.loanPayments,
    required this.budgets,
    required this.goals,
    required this.goalContributions,
    required this.recurring,
    required this.tours,
    required this.tourCollections,
    required this.tourExpenses,
  });

  final int accounts;
  final int transfers;
  final int transactions;
  final int loans;
  final int loanPayments;
  final int budgets;
  final int goals;
  final int goalContributions;
  final int recurring;
  final int tours;
  final int tourCollections;
  final int tourExpenses;

  int get total =>
      accounts +
      transfers +
      transactions +
      loans +
      loanPayments +
      budgets +
      goals +
      goalContributions +
      recurring +
      tours +
      tourCollections +
      tourExpenses;

  @override
  List<Object?> get props => [
    accounts,
    transfers,
    transactions,
    loans,
    loanPayments,
    budgets,
    goals,
    goalContributions,
    recurring,
    tours,
    tourCollections,
    tourExpenses,
  ];
}
