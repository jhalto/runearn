import 'package:equatable/equatable.dart';

class LoanPayment extends Equatable {
  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String note;

  @override
  List<Object?> get props => [id, loanId, amount, date, note];
}
