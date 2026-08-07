import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/accounts/domain/entities/financial_position.dart';

void main() {
  test('net worth equals assets minus liabilities', () {
    const position = FinancialPosition(
      cash: 5000,
      loanGiven: 3000,
      loanTaken: 8000,
    );

    expect(position.totalAssets, 8000);
    expect(position.totalLiabilities, 8000);
    expect(position.netWorth, 0);
  });
}
