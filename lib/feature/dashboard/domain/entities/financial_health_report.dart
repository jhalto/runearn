import 'package:equatable/equatable.dart';

class FinancialHealthIndicator extends Equatable {
  const FinancialHealthIndicator({
    required this.label,
    required this.score,
    required this.maximum,
    required this.detail,
  });

  final String label;
  final int score;
  final int maximum;
  final String detail;

  @override
  List<Object?> get props => [label, score, maximum, detail];
}

class FinancialHealthReport extends Equatable {
  const FinancialHealthReport({
    required this.score,
    required this.indicators,
    required this.recommendations,
  });

  final int score;
  final List<FinancialHealthIndicator> indicators;
  final List<String> recommendations;

  String get label => switch (score) {
    >= 80 => 'Strong',
    >= 60 => 'Stable',
    >= 40 => 'Needs attention',
    _ => 'At risk',
  };

  @override
  List<Object?> get props => [score, indicators, recommendations];
}
