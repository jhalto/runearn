import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';

class LoanBalanceCalculator {
  const LoanBalanceCalculator._();

  static LoanBalance calculate(
    Loan loan,
    Iterable<LoanPayment> payments, {
    DateTime? asOf,
  }) {
    final calculationDate = _calculationDate(loan, asOf ?? DateTime.now());
    final days = math.max(
      0,
      DateTime(calculationDate.year, calculationDate.month, calculationDate.day)
          .difference(
            DateTime(
              loan.issuedAt.year,
              loan.issuedAt.month,
              loan.issuedAt.day,
            ),
          )
          .inDays,
    );
    final years = days / 365;
    final rate = loan.annualInterestRate / 100;
    final interest = switch (loan.interestMethod) {
      LoanInterestMethod.none => 0.0,
      LoanInterestMethod.simple => loan.amount * rate * years,
      LoanInterestMethod.compoundMonthly =>
        loan.amount * (math.pow(1 + (rate / 12), years * 12) - 1),
    };
    final paid = payments
        .where(
          (payment) =>
              payment.loanId == loan.id &&
              !payment.date.isAfter(calculationDate),
        )
        .fold<double>(0, (total, payment) => total + payment.amount);
    final totalDue = loan.amount + interest;
    final outstanding = loan.isSettled
        ? 0.0
        : (totalDue - paid).clamp(0, totalDue).toDouble();
    return LoanBalance(
      principal: loan.amount,
      accruedInterest: interest,
      totalDue: totalDue,
      paid: paid,
      outstanding: outstanding,
      calculatedThrough: calculationDate,
    );
  }

  static DateTime _calculationDate(Loan loan, DateTime asOf) {
    if (asOf.isBefore(loan.issuedAt)) return loan.issuedAt;
    final due = loan.dueAt;
    if (due != null && asOf.isAfter(due)) return due;
    return asOf;
  }
}

class LoanBalance extends Equatable {
  const LoanBalance({
    required this.principal,
    required this.accruedInterest,
    required this.totalDue,
    required this.paid,
    required this.outstanding,
    required this.calculatedThrough,
  });

  final double principal;
  final double accruedInterest;
  final double totalDue;
  final double paid;
  final double outstanding;
  final DateTime calculatedThrough;

  @override
  List<Object?> get props => [
    principal,
    accruedInterest,
    totalDue,
    paid,
    outstanding,
    calculatedThrough,
  ];
}
