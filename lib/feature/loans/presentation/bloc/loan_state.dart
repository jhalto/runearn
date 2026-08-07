import 'package:equatable/equatable.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/services/loan_balance_calculator.dart';

sealed class LoanState extends Equatable {
  const LoanState();

  @override
  List<Object?> get props => const [];
}

final class LoanInitial extends LoanState {
  const LoanInitial();
}

final class LoanLoading extends LoanState {
  const LoanLoading();
}

final class LoanLoaded extends LoanState {
  final List<Loan> loans;
  final List<LoanPayment> payments;

  LoanLoaded(List<Loan> loans, [List<LoanPayment> payments = const []])
    : loans = List.unmodifiable(loans),
      payments = List.unmodifiable(payments);

  List<Loan> forDirection(LoanDirection direction) => loans
      .where((loan) => loan.direction == direction)
      .toList(growable: false);

  List<LoanPayment> paymentsFor(String loanId) => payments
      .where((payment) => payment.loanId == loanId)
      .toList(growable: false);

  double paidFor(String loanId) => payments
      .where((payment) => payment.loanId == loanId)
      .fold(0, (total, payment) => total + payment.amount);

  LoanBalance balanceFor(Loan loan, {DateTime? asOf}) =>
      LoanBalanceCalculator.calculate(loan, paymentsFor(loan.id), asOf: asOf);

  double remainingFor(Loan loan) => balanceFor(loan).outstanding;

  double outstandingFor(LoanDirection direction) => loans
      .where((loan) => loan.direction == direction)
      .fold(0, (total, loan) => total + remainingFor(loan));

  @override
  List<Object?> get props => [loans, payments];
}

final class LoanFailure extends LoanState {
  final String message;

  const LoanFailure(this.message);

  @override
  List<Object?> get props => [message];
}
