import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:runearn/feature/dashboard/data/dashboard_preferences_store.dart';
import 'package:runearn/feature/dashboard/domain/entities/dashboard_preferences.dart';
import 'package:runearn/feature/dashboard/domain/services/financial_health_calculator.dart';
import 'package:runearn/feature/dashboard/presentation/widgets/financial_health_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'health calculation, presentation, and preferences work together',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = DashboardPreferencesStore();
      final preferences = DashboardPreferences.defaults().copyWith(
        visible: {DashboardSection.overview, DashboardSection.health},
      );
      await store.save(preferences);
      final restored = await store.load();
      expect(restored.visible, preferences.visible);

      final report = FinancialHealthCalculator.calculate(
        monthlyIncome: 8000,
        monthlyExpense: 5000,
        assets: 50000,
        liabilities: 5000,
        budgetLimit: 6000,
        budgetSpent: 5000,
        overdueObligations: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FinancialHealthCard(report: report)),
        ),
      );

      expect(find.textContaining('Financial health'), findsOneWidget);
      await tester.tap(find.textContaining('Financial health'));
      await tester.pumpAndSettle();
      expect(find.text('Cash flow'), findsOneWidget);
      expect(find.text('Debt position'), findsOneWidget);
    },
  );
}
