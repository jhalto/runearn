import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/services/account_balance_calculator.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

void main() {
  test('asset balance applies only linked income and expense', () {
    final account = FinanceAccount(
      id: 'cash',
      name: 'Cash',
      type: FinanceAccountType.cash,
      balance: 1000,
      createdAt: DateTime(2026),
    );
    final transactions = [
      _transaction('income', 500, TransactionType.income, 'cash'),
      _transaction('expense', 200, TransactionType.expense, 'cash'),
      _transaction('other', 900, TransactionType.income, 'bank'),
    ];

    expect(AccountBalanceCalculator.calculate(account, transactions), 1300);
  });

  test(
    'asset-to-asset transfer moves balance without changing total assets',
    () {
      final cash = FinanceAccount(
        id: 'cash',
        name: 'Cash',
        type: FinanceAccountType.cash,
        balance: 1000,
        createdAt: DateTime(2026),
      );
      final bank = FinanceAccount(
        id: 'bank',
        name: 'Bank',
        type: FinanceAccountType.bank,
        balance: 2000,
        createdAt: DateTime(2026),
      );
      final transfer = AccountTransfer(
        id: 'transfer',
        fromAccountId: 'bank',
        toAccountId: 'cash',
        amount: 500,
        date: DateTime(2026),
      );

      final cashBalance = AccountBalanceCalculator.calculate(cash, const [], [
        transfer,
      ]);
      final bankBalance = AccountBalanceCalculator.calculate(bank, const [], [
        transfer,
      ]);

      expect(cashBalance, 1500);
      expect(bankBalance, 1500);
      expect(cashBalance + bankBalance, 3000);
    },
  );

  test('uses received amount for a cross-currency destination', () {
    final usd = FinanceAccount(
      id: 'usd',
      name: 'USD account',
      type: FinanceAccountType.bank,
      balance: 0,
      currencyCode: 'USD',
      createdAt: DateTime(2026),
    );
    final bdt = FinanceAccount(
      id: 'bdt',
      name: 'BDT account',
      type: FinanceAccountType.bank,
      balance: 0,
      createdAt: DateTime(2026),
    );
    final transfer = AccountTransfer(
      id: 'fx',
      fromAccountId: usd.id,
      toAccountId: bdt.id,
      amount: 10,
      receivedAmount: 1220,
      date: DateTime(2026),
    );

    expect(AccountBalanceCalculator.calculate(usd, const [], [transfer]), -10);
    expect(AccountBalanceCalculator.calculate(bdt, const [], [transfer]), 1220);
  });
}

Transaction _transaction(
  String id,
  double amount,
  TransactionType type,
  String accountId,
) => Transaction(
  id: id,
  amount: amount,
  type: type,
  category: TransactionCategory.other,
  accountId: accountId,
  description: '',
  date: DateTime(2026),
);
