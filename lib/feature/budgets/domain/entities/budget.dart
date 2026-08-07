import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.categoryName,
    required this.limit,
    required this.month,
    this.rolloverEnabled = false,
    this.isTemplate = false,
    this.templateName = '',
  });

  final String id;
  final String categoryName;
  final double limit;
  final DateTime month;
  final bool rolloverEnabled;
  final bool isTemplate;
  final String templateName;

  Budget copyWith({
    String? categoryName,
    double? limit,
    DateTime? month,
    bool? rolloverEnabled,
    bool? isTemplate,
    String? templateName,
  }) => Budget(
    id: id,
    categoryName: categoryName ?? this.categoryName,
    limit: limit ?? this.limit,
    month: month ?? this.month,
    rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
    isTemplate: isTemplate ?? this.isTemplate,
    templateName: templateName ?? this.templateName,
  );

  @override
  List<Object?> get props => [
    id,
    categoryName,
    limit,
    month,
    rolloverEnabled,
    isTemplate,
    templateName,
  ];
}
