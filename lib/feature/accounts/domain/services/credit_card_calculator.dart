import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';

class CreditCardSummary extends Equatable {
  const CreditCardSummary({
    required this.outstanding,
    required this.availableCredit,
    required this.utilizationPercent,
    required this.minimumPayment,
    required this.nextStatementDate,
    required this.paymentDueDate,
  });

  final double outstanding;
  final double availableCredit;
  final double utilizationPercent;
  final double minimumPayment;
  final DateTime nextStatementDate;
  final DateTime paymentDueDate;

  @override
  List<Object?> get props => [
    outstanding,
    availableCredit,
    utilizationPercent,
    minimumPayment,
    nextStatementDate,
    paymentDueDate,
  ];
}

class CreditCardCalculator {
  const CreditCardCalculator._();

  static CreditCardSummary calculate(
    FinanceAccount account,
    double currentBalance, {
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final outstanding = math.max(0.0, currentBalance);
    final limit = math.max(0.0, account.creditLimit ?? 0);
    final statementDay = account.statementDay ?? 1;
    var statement = _date(now.year, now.month, statementDay);
    if (!statement.isAfter(now)) {
      statement = _date(now.year, now.month + 1, statementDay);
    }
    final dueDay = account.paymentDueDay ?? 1;
    var due = _date(now.year, now.month, dueDay);
    if (!due.isAfter(now)) due = _date(now.year, now.month + 1, dueDay);
    final percentage = outstanding * account.minimumPaymentPercent / 100;
    return CreditCardSummary(
      outstanding: outstanding,
      availableCredit: math.max(0.0, limit - outstanding),
      utilizationPercent: limit == 0 ? 0 : outstanding / limit * 100,
      minimumPayment: math.min(
        outstanding,
        math.max(percentage, account.minimumPaymentAmount),
      ),
      nextStatementDate: statement,
      paymentDueDate: due,
    );
  }

  static DateTime _date(int year, int month, int day) {
    final normalized = DateTime(year, month);
    final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
    return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
  }
}
