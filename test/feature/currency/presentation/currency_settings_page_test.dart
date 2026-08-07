import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/currency/data/currency_preferences.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/currency/presentation/pages/currency_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens settings and searches a currency by country', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = CurrencyCubit(const CurrencyPreferences());
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const CurrencySettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Currencies'), findsOneWidget);

    await tester.tap(find.text('Add rate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Canada');
    await tester.pump();

    final cad = find.textContaining('CAD').last;
    expect(cad, findsOneWidget);
    await tester.tap(cad);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0.01');
    await tester.tap(find.text('Save rate'));
    await tester.pumpAndSettle();

    expect(cubit.state.rates, contains('CAD'));

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Canada');
    await tester.pump();
    await tester.tap(find.textContaining('CAD').last);
    await tester.pumpAndSettle();

    expect(cubit.state.baseCurrency, 'CAD');
    expect(tester.takeException(), isNull);
  });
}
