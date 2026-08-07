import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/net_worth/domain/services/net_worth_calculator.dart';

void main() {
  test('calculates net worth from accounts and outstanding loans', () {
    final now = DateTime(2026);
    final snapshot = NetWorthCalculator.calculate(
      accounts: [
        FinanceAccount(
          id: 'cash',
          name: 'Cash',
          type: FinanceAccountType.cash,
          balance: 5000,
          createdAt: now,
        ),
      ],
      transactions: const [],
      transfers: const [],
      loans: [
        Loan(
          id: 'given',
          personName: 'Rahim',
          amount: 3000,
          direction: LoanDirection.lent,
          issuedAt: now,
        ),
        Loan(
          id: 'taken',
          personName: 'Karim',
          amount: 8000,
          direction: LoanDirection.borrowed,
          issuedAt: now,
        ),
      ],
      payments: [
        LoanPayment(id: 'payment', loanId: 'given', amount: 1000, date: now),
      ],
    );

    expect(snapshot.totalAssets, 7000);
    expect(snapshot.totalLiabilities, 8000);
    expect(snapshot.netWorth, -1000);
  });

  test('ignores settled loans and non-balance account classifications', () {
    final now = DateTime(2026);
    final snapshot = NetWorthCalculator.calculate(
      accounts: [
        FinanceAccount(
          id: 'income',
          name: 'Salary',
          type: FinanceAccountType.income,
          balance: 10000,
          createdAt: now,
        ),
      ],
      transactions: const [],
      transfers: const [],
      loans: [
        Loan(
          id: 'settled',
          personName: 'Settled',
          amount: 4000,
          direction: LoanDirection.lent,
          issuedAt: now,
          isSettled: true,
        ),
      ],
      payments: const [],
    );

    expect(snapshot.totalAssets, 0);
    expect(snapshot.totalLiabilities, 0);
    expect(snapshot.netWorth, 0);
  });
}
