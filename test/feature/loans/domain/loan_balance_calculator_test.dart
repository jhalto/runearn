import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/services/loan_balance_calculator.dart';

void main() {
  Loan loan(LoanInterestMethod method, double rate) => Loan(
    id: 'loan-1',
    personName: 'Alex',
    amount: 10000,
    direction: LoanDirection.lent,
    issuedAt: DateTime(2025, 1, 1),
    dueAt: DateTime(2026, 1, 1),
    interestMethod: method,
    annualInterestRate: rate,
  );

  test('calculates one year of simple interest', () {
    final balance = LoanBalanceCalculator.calculate(
      loan(LoanInterestMethod.simple, 10),
      const [],
      asOf: DateTime(2026, 1, 1),
    );

    expect(balance.accruedInterest, closeTo(1000, .01));
    expect(balance.totalDue, closeTo(11000, .01));
    expect(balance.outstanding, closeTo(11000, .01));
  });

  test('calculates monthly compound interest', () {
    final balance = LoanBalanceCalculator.calculate(
      loan(LoanInterestMethod.compoundMonthly, 12),
      const [],
      asOf: DateTime(2026, 1, 1),
    );

    expect(balance.totalDue, closeTo(11268.25, .1));
  });

  test('payments reduce total payoff and future payments are ignored', () {
    final balance =
        LoanBalanceCalculator.calculate(loan(LoanInterestMethod.simple, 10), [
          LoanPayment(
            id: 'paid',
            loanId: 'loan-1',
            amount: 2000,
            date: DateTime(2025, 6, 1),
          ),
          LoanPayment(
            id: 'future',
            loanId: 'loan-1',
            amount: 500,
            date: DateTime(2026, 2, 1),
          ),
        ], asOf: DateTime(2026, 1, 1));

    expect(balance.paid, 2000);
    expect(balance.outstanding, closeTo(9000, .01));
  });

  test('interest stops accruing at the contractual due date', () {
    final balance = LoanBalanceCalculator.calculate(
      loan(LoanInterestMethod.simple, 10),
      const [],
      asOf: DateTime(2027, 1, 1),
    );

    expect(balance.accruedInterest, closeTo(1000, .01));
  });
}
