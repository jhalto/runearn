import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/services/credit_card_calculator.dart';

void main() {
  final account = FinanceAccount(
    id: 'card',
    name: 'Everyday card',
    type: FinanceAccountType.creditCard,
    balance: 0,
    createdAt: DateTime.utc(2026),
    creditLimit: 10000,
    statementDay: 12,
    paymentDueDay: 27,
    minimumPaymentPercent: 5,
    minimumPaymentAmount: 500,
  );

  test('calculates utilization, available credit, and minimum payment', () {
    final result = CreditCardCalculator.calculate(
      account,
      4000,
      asOf: DateTime(2026, 7, 20),
    );

    expect(result.availableCredit, 6000);
    expect(result.utilizationPercent, 40);
    expect(result.minimumPayment, 500);
    expect(result.nextStatementDate, DateTime(2026, 8, 12));
    expect(result.paymentDueDate, DateTime(2026, 7, 27));
  });

  test('minimum payment never exceeds outstanding balance', () {
    final result = CreditCardCalculator.calculate(
      account,
      200,
      asOf: DateTime(2026, 7, 28),
    );

    expect(result.minimumPayment, 200);
    expect(result.paymentDueDate, DateTime(2026, 8, 27));
  });
}
