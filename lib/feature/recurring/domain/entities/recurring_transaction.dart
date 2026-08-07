import 'package:equatable/equatable.dart';
import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class RecurringTransaction extends Equatable {
  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.nextDue,
    this.customCategory,
    this.accountId,
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategory;
  final String? accountId;
  final RecurrenceFrequency frequency;
  final DateTime nextDue;
  final String note;
  final bool isActive;

  String get categoryName => customCategory?.trim().isNotEmpty == true
      ? customCategory!.trim()
      : category.label;

  RecurringTransaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? customCategory,
    bool clearCustomCategory = false,
    String? accountId,
    bool clearAccountId = false,
    RecurrenceFrequency? frequency,
    DateTime? nextDue,
    String? note,
    bool? isActive,
  }) => RecurringTransaction(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    category: category ?? this.category,
    customCategory: clearCustomCategory
        ? null
        : customCategory ?? this.customCategory,
    accountId: clearAccountId ? null : accountId ?? this.accountId,
    frequency: frequency ?? this.frequency,
    nextDue: nextDue ?? this.nextDue,
    note: note ?? this.note,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    category,
    customCategory,
    accountId,
    frequency,
    nextDue,
    note,
    isActive,
  ];
}
