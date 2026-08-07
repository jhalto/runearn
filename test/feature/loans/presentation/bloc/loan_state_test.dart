import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';

void main() {
  test('LoanLoaded filters direction and totals only active loans', () {
    final loans = [
      Loan(
        id: '1',
        personName: 'A',
        amount: 100,
        direction: LoanDirection.lent,
        issuedAt: DateTime.utc(2026),
      ),
      Loan(
        id: '2',
        personName: 'B',
        amount: 40,
        direction: LoanDirection.lent,
        issuedAt: DateTime.utc(2026),
        isSettled: true,
      ),
      Loan(
        id: '3',
        personName: 'C',
        amount: 75,
        direction: LoanDirection.borrowed,
        issuedAt: DateTime.utc(2026),
      ),
    ];

    final state = LoanLoaded(loans);

    expect(state.forDirection(LoanDirection.lent), hasLength(2));
    expect(state.outstandingFor(LoanDirection.lent), 100);
    expect(state.outstandingFor(LoanDirection.borrowed), 75);
  });

  test('equivalent loaded states compare equal', () {
    final loan = Loan(
      id: '1',
      personName: 'A',
      amount: 100,
      direction: LoanDirection.lent,
      issuedAt: DateTime.utc(2026),
    );

    expect(LoanLoaded([loan]), LoanLoaded([loan]));
  });

  test('partial payments reduce outstanding loan balance', () {
    final loan = Loan(
      id: 'loan',
      personName: 'A',
      amount: 2000,
      direction: LoanDirection.lent,
      issuedAt: DateTime.utc(2026),
    );
    final payments = [
      LoanPayment(
        id: 'payment',
        loanId: loan.id,
        amount: 750,
        date: DateTime.utc(2026, 2),
      ),
    ];

    final state = LoanLoaded([loan], payments);

    expect(state.paidFor(loan.id), 750);
    expect(state.remainingFor(loan), 1250);
    expect(state.outstandingFor(LoanDirection.lent), 1250);
  });
}
