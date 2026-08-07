import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/search/domain/entities/transaction_filter.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

void main() {
  final items = [
    Transaction(
      id: '1',
      amount: 800,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      description: 'Team lunch',
      date: DateTime(2026, 7, 20),
      tags: const ['office', 'tax'],
    ),
    Transaction(
      id: '2',
      amount: 5000,
      type: TransactionType.income,
      category: TransactionCategory.freelance,
      description: 'Website project',
      date: DateTime(2026, 7, 22),
      tags: const ['client'],
    ),
  ];

  test('filters locally by text, type, tag, amount, and date', () {
    final filter = TransactionFilter(
      query: 'lunch',
      type: TransactionType.expense,
      tags: const {'office'},
      minimumAmount: 500,
      maximumAmount: 1000,
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );

    expect(filter.apply(items).map((item) => item.id), ['1']);
  });

  test('sorts by amount and survives serialization', () {
    const filter = TransactionFilter(sort: TransactionSort.amountHigh);
    final restored = TransactionFilter.fromMap(filter.toMap());

    expect(restored, filter);
    expect(restored.apply(items).map((item) => item.id), ['2', '1']);
  });
}
