import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/widgets/transaction_split_field.dart';

void main() {
  testWidgets('empty amount shows validation instead of opening or crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionSplitField(
            type: TransactionType.income,
            splits: const [],
            totalProvider: () => 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Split across categories'));
    await tester.pump();

    expect(find.text('Enter the transaction amount first.'), findsOneWidget);
    expect(find.text('Split transaction'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the income split editor without an exception', (
    tester,
  ) async {
    var splits = <TransactionSplit>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionSplitField(
            type: TransactionType.income,
            splits: splits,
            totalProvider: () => 100,
            onChanged: (value) => splits = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Split across categories'));
    await tester.pumpAndSettle();

    expect(find.text('Split transaction'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final amountFields = find.byType(TextField);
    expect(amountFields, findsNWidgets(2));
    await tester.enterText(amountFields.at(0), '50');
    await tester.enterText(amountFields.at(1), '50');
    await tester.tap(find.text('Apply split'));
    await tester.pumpAndSettle();

    expect(splits, hasLength(2));
    expect(splits.fold<double>(0, (sum, split) => sum + split.amount), 100);
    expect(tester.takeException(), isNull);
  });
}
