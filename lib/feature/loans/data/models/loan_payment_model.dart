import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';

class LoanPaymentModel {
  const LoanPaymentModel({
    required this.id,
    required this.userId,
    required this.loanId,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String userId;
  final String loanId;
  final double amount;
  final String date;
  final String note;

  factory LoanPaymentModel.fromEntity(
    LoanPayment payment, {
    required String userId,
  }) => LoanPaymentModel(
    id: payment.id,
    userId: userId,
    loanId: payment.loanId,
    amount: payment.amount,
    date: payment.date.toIso8601String(),
    note: payment.note,
  );

  factory LoanPaymentModel.fromMap(Map<String, dynamic> map) =>
      LoanPaymentModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        loanId: map['loanId'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'loanId': loanId,
    'amount': amount,
    'date': date,
    'note': note,
  };

  LoanPayment toEntity() => LoanPayment(
    id: id,
    loanId: loanId,
    amount: amount,
    date: DateTime.parse(date),
    note: note,
  );
}
