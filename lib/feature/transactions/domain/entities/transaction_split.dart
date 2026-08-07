import 'package:equatable/equatable.dart';
import 'transaction_category.dart';

class TransactionSplit extends Equatable {
  const TransactionSplit({
    required this.category,
    required this.amount,
    this.customCategory,
  });

  final TransactionCategory category;
  final String? customCategory;
  final double amount;

  String get categoryName => customCategory?.trim().isNotEmpty == true
      ? customCategory!.trim()
      : category.label;

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'customCategory': customCategory,
    'amount': amount,
  };

  factory TransactionSplit.fromMap(Map<String, dynamic> map) =>
      TransactionSplit(
        category: TransactionCategory.values.firstWhere(
          (value) => value.name == map['category'],
          orElse: () => TransactionCategory.other,
        ),
        customCategory: map['customCategory'] as String?,
        amount: (map['amount'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [category, customCategory, amount];
}
