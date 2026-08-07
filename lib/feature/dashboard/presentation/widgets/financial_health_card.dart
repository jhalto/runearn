import 'package:flutter/material.dart';
import 'package:runearn/feature/dashboard/domain/entities/financial_health_report.dart';

class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({required this.report, super.key});

  final FinancialHealthReport report;

  @override
  Widget build(BuildContext context) {
    final color = switch (report.score) {
      >= 80 => Colors.green,
      >= 60 => Colors.teal,
      >= 40 => Colors.orange,
      _ => Theme.of(context).colorScheme.error,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: SizedBox.square(
          dimension: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: report.score / 100,
                strokeWidth: 6,
                color: color,
                backgroundColor: color.withValues(alpha: .15),
              ),
              Center(
                child: Text(
                  '${report.score}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Financial health • ${report.label}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Tap to see the score breakdown'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          for (final indicator in report.indicators) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(indicator.label)),
                Text('${indicator.score}/${indicator.maximum}'),
              ],
            ),
            LinearProgressIndicator(
              value: indicator.score / indicator.maximum,
              color: color,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(indicator.detail),
            ),
          ],
          if (report.recommendations.isNotEmpty) ...[
            const Divider(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recommended next steps',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final recommendation in report.recommendations)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.arrow_right_rounded, color: color),
                title: Text(recommendation),
              ),
          ],
        ],
      ),
    );
  }
}
