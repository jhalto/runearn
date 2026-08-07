import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/dashboard/domain/entities/financial_health_report.dart';
import 'package:runearn/feature/dashboard/presentation/widgets/financial_health_card.dart';

void main() {
  testWidgets('shows summary then expands score details', (tester) async {
    const report = FinancialHealthReport(
      score: 72,
      indicators: [
        FinancialHealthIndicator(
          label: 'Cash flow',
          score: 20,
          maximum: 25,
          detail: '20% savings rate',
        ),
      ],
      recommendations: ['Build emergency savings.'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FinancialHealthCard(report: report)),
      ),
    );

    expect(find.text('Financial health • Stable'), findsOneWidget);
    expect(find.text('20% savings rate'), findsNothing);

    await tester.tap(find.text('Financial health • Stable'));
    await tester.pumpAndSettle();

    expect(find.text('Cash flow'), findsOneWidget);
    expect(find.text('20/25'), findsOneWidget);
    expect(find.text('20% savings rate'), findsOneWidget);
    expect(find.text('Build emergency savings.'), findsOneWidget);
  });
}
