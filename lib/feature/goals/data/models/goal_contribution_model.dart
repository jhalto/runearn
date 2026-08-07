import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';

class GoalContributionModel {
  const GoalContributionModel({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.amount,
    required this.date,
    required this.note,
    this.sourceAccountId,
    this.goalAccountId,
    this.transferId,
  });

  final String id;
  final String userId;
  final String goalId;
  final double amount;
  final String date;
  final String note;
  final String? sourceAccountId;
  final String? goalAccountId;
  final String? transferId;

  factory GoalContributionModel.fromEntity(
    GoalContribution contribution,
    String userId,
  ) => GoalContributionModel(
    id: contribution.id,
    userId: userId,
    goalId: contribution.goalId,
    amount: contribution.amount,
    date: contribution.date.toIso8601String(),
    note: contribution.note,
    sourceAccountId: contribution.sourceAccountId,
    goalAccountId: contribution.goalAccountId,
    transferId: contribution.transferId,
  );

  factory GoalContributionModel.fromMap(Map<String, dynamic> map) =>
      GoalContributionModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        goalId: map['goalId'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String? ?? '',
        sourceAccountId: map['sourceAccountId'] as String?,
        goalAccountId: map['goalAccountId'] as String?,
        transferId: map['transferId'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'goalId': goalId,
    'amount': amount,
    'date': date,
    'note': note,
    'sourceAccountId': sourceAccountId,
    'goalAccountId': goalAccountId,
    'transferId': transferId,
  };

  GoalContribution toEntity() => GoalContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    date: DateTime.parse(date),
    note: note,
    sourceAccountId: sourceAccountId,
    goalAccountId: goalAccountId,
    transferId: transferId,
  );
}
