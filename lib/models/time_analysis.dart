class TimeAnalytics {
  final String label; // e.g. "Week 1", "Jan 2026"
  final double income;
  final double expense;

  TimeAnalytics({
    required this.label,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}