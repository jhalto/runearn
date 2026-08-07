import 'package:equatable/equatable.dart';

class FinancialPosition extends Equatable {
  const FinancialPosition({
    required this.cash,
    this.bank = 0,
    this.investment = 0,
    this.loanGiven = 0,
    this.loanTaken = 0,
    this.creditCard = 0,
    this.mortgage = 0,
    this.otherAssets = 0,
    this.otherLiabilities = 0,
  });

  final double cash;
  final double bank;
  final double investment;
  final double loanGiven;
  final double loanTaken;
  final double creditCard;
  final double mortgage;
  final double otherAssets;
  final double otherLiabilities;

  double get totalAssets => cash + bank + investment + loanGiven + otherAssets;

  double get totalLiabilities =>
      loanTaken + creditCard + mortgage + otherLiabilities;

  double get netWorth => totalAssets - totalLiabilities;

  @override
  List<Object?> get props => [
    cash,
    bank,
    investment,
    loanGiven,
    loanTaken,
    creditCard,
    mortgage,
    otherAssets,
    otherLiabilities,
  ];
}
