import 'package:equatable/equatable.dart';

class ExchangeRate extends Equatable {
  const ExchangeRate({
    required this.currencyCode,
    required this.rateToBase,
    required this.updatedAt,
  });

  final String currencyCode;

  /// Amount of the base currency equal to one unit of [currencyCode].
  final double rateToBase;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [currencyCode, rateToBase, updatedAt];
}
