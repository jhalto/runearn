import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';

class GoalModel {
  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    required this.deadline,
    required this.note,
  });

  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final String createdAt;
  final String? deadline;
  final String note;

  factory GoalModel.fromEntity(FinancialGoal goal, String userId) => GoalModel(
    id: goal.id,
    userId: userId,
    name: goal.name,
    targetAmount: goal.targetAmount,
    createdAt: goal.createdAt.toIso8601String(),
    deadline: goal.deadline?.toIso8601String(),
    note: goal.note,
  );

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    name: map['name'] as String,
    targetAmount: (map['targetAmount'] as num).toDouble(),
    createdAt: map['createdAt'] as String,
    deadline: map['deadline'] as String?,
    note: map['note'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'targetAmount': targetAmount,
    'createdAt': createdAt,
    'deadline': deadline,
    'note': note,
  };

  FinancialGoal toEntity() => FinancialGoal(
    id: id,
    name: name,
    targetAmount: targetAmount,
    createdAt: DateTime.parse(createdAt),
    deadline: deadline == null ? null : DateTime.parse(deadline!),
    note: note,
  );
}
