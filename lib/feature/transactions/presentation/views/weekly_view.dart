import 'package:flutter/material.dart';
import 'package:runearn/feature/transactions/presentation/views/period_report_view.dart';

class WeeklyView extends StatelessWidget {
  const WeeklyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeriodReportView(period: ReportPeriod.weekly);
  }
}
