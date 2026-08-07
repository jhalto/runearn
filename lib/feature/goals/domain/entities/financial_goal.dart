import 'package:equatable/equatable.dart';

class FinancialGoal extends Equatable {
  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.deadline,
    this.note = '',
  });

  final String id;
  final String name;
  final double targetAmount;
  final DateTime createdAt;
  final DateTime? deadline;
  final String note;

  FinancialGoal copyWith({
    String? name,
    double? targetAmount,
    DateTime? deadline,
    bool clearDeadline = false,
    String? note,
  }) => FinancialGoal(
    id: id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    createdAt: createdAt,
    deadline: clearDeadline ? null : deadline ?? this.deadline,
    note: note ?? this.note,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    createdAt,
    deadline,
    note,
  ];
}
