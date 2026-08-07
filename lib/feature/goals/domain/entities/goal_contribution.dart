import 'package:equatable/equatable.dart';

class GoalContribution extends Equatable {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note = '',
    this.sourceAccountId,
    this.goalAccountId,
    this.transferId,
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String note;
  final String? sourceAccountId;
  final String? goalAccountId;
  final String? transferId;

  @override
  List<Object?> get props => [
    id,
    goalId,
    amount,
    date,
    note,
    sourceAccountId,
    goalAccountId,
    transferId,
  ];
}
