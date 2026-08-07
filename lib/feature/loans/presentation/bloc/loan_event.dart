import 'package:equatable/equatable.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';

sealed class LoanEvent extends Equatable {
  const LoanEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadLoans extends LoanEvent {
  const LoadLoans();
}

final class ResetLoans extends LoanEvent {
  const ResetLoans();
}

final class SyncPendingLoansRequested extends LoanEvent {
  const SyncPendingLoansRequested();
}

final class AddLoanRequested extends LoanEvent {
  final Loan loan;

  const AddLoanRequested(this.loan);

  @override
  List<Object?> get props => [loan];
}

final class LoanSettlementChanged extends LoanEvent {
  final Loan loan;

  const LoanSettlementChanged(this.loan);

  @override
  List<Object?> get props => [loan];
}

final class UpdateLoanRequested extends LoanEvent {
  final Loan loan;

  const UpdateLoanRequested(this.loan);

  @override
  List<Object?> get props => [loan];
}

final class DeleteLoanRequested extends LoanEvent {
  final String id;

  const DeleteLoanRequested(this.id);

  @override
  List<Object?> get props => [id];
}

final class AddLoanPaymentRequested extends LoanEvent {
  const AddLoanPaymentRequested(this.payment);
  final LoanPayment payment;
  @override
  List<Object?> get props => [payment];
}

final class DeleteLoanPaymentRequested extends LoanEvent {
  const DeleteLoanPaymentRequested(this.payment);
  final LoanPayment payment;
  @override
  List<Object?> get props => [payment];
}
