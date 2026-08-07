import 'package:runearn/feature/budgets/domain/entities/budget.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryName,
    required this.limit,
    required this.month,
    required this.rolloverEnabled,
    required this.isTemplate,
    required this.templateName,
  });

  final String id;
  final String userId;
  final String categoryName;
  final double limit;
  final String month;
  final bool rolloverEnabled;
  final bool isTemplate;
  final String templateName;

  factory BudgetModel.fromEntity(Budget budget, String userId) => BudgetModel(
    id: budget.id,
    userId: userId,
    categoryName: budget.categoryName,
    limit: budget.limit,
    month: DateTime(budget.month.year, budget.month.month).toIso8601String(),
    rolloverEnabled: budget.rolloverEnabled,
    isTemplate: budget.isTemplate,
    templateName: budget.templateName,
  );

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    categoryName: map['categoryName'] as String,
    limit: (map['limit'] as num).toDouble(),
    month: map['month'] as String,
    rolloverEnabled: (map['rolloverEnabled'] as num?)?.toInt() == 1,
    isTemplate: (map['isTemplate'] as num?)?.toInt() == 1,
    templateName: map['templateName'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'categoryName': categoryName,
    'limit': limit,
    'month': month,
    'rolloverEnabled': rolloverEnabled ? 1 : 0,
    'isTemplate': isTemplate ? 1 : 0,
    'templateName': templateName,
  };

  Budget toEntity() => Budget(
    id: id,
    categoryName: categoryName,
    limit: limit,
    month: DateTime.parse(month),
    rolloverEnabled: rolloverEnabled,
    isTemplate: isTemplate,
    templateName: templateName,
  );
}
