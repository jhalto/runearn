import 'package:equatable/equatable.dart';

import 'transaction_type.dart';
import 'transaction_category.dart';
import 'transaction_split.dart';

class Transaction extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategory;
  final String? accountId;
  final String description;
  final DateTime date;
  final String? localReceiptPath;
  final List<String> tags;
  final List<TransactionSplit> splits;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategory,
    this.accountId,
    required this.description,
    required this.date,
    this.localReceiptPath,
    this.tags = const [],
    this.splits = const [],
  });

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? customCategory,
    bool clearCustomCategory = false,
    String? accountId,
    bool clearAccountId = false,
    String? description,
    DateTime? date,
    String? localReceiptPath,
    bool clearLocalReceipt = false,
    List<String>? tags,
    List<TransactionSplit>? splits,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      customCategory: clearCustomCategory
          ? null
          : customCategory ?? this.customCategory,
      accountId: clearAccountId ? null : accountId ?? this.accountId,
      description: description ?? this.description,
      date: date ?? this.date,
      localReceiptPath: clearLocalReceipt
          ? null
          : localReceiptPath ?? this.localReceiptPath,
      tags: tags ?? this.tags,
      splits: splits ?? this.splits,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    type,
    category,
    customCategory,
    accountId,
    description,
    date,
    localReceiptPath,
    tags,
    splits,
  ];

  String get categoryName => customCategory?.trim().isNotEmpty == true
      ? customCategory!.trim()
      : category.label;

  bool get isSplit => splits.length > 1;

  Iterable<TransactionSplit> get categoryAllocations sync* {
    if (splits.isNotEmpty) {
      yield* splits;
      return;
    }
    yield TransactionSplit(
      category: category,
      customCategory: customCategory,
      amount: amount,
    );
  }
}
