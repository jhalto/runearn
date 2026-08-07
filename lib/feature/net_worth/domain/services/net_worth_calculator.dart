import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/services/account_balance_calculator.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/services/loan_balance_calculator.dart';
import 'package:runearn/feature/net_worth/domain/entities/net_worth_snapshot.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';

class NetWorthCalculator {
  const NetWorthCalculator._();

  static NetWorthSnapshot calculate({
    required Iterable<FinanceAccount> accounts,
    required Iterable<Transaction> transactions,
    required Iterable<AccountTransfer> transfers,
    required Iterable<Loan> loans,
    required Iterable<LoanPayment> payments,
    double Function(double amount, String currencyCode)? toBase,
    String baseCurrency = 'BDT',
  }) {
    final convert = toBase ?? (amount, _) => amount;
    final assets = <NetWorthItem>[];
    final liabilities = <NetWorthItem>[];

    for (final account in accounts) {
      final classification = account.type.classification;
      if (classification != AccountClassification.asset &&
          classification != AccountClassification.liability) {
        continue;
      }
      final item = NetWorthItem(
        id: account.id,
        name: account.name,
        type: account.type,
        value: convert(
          AccountBalanceCalculator.calculate(account, transactions, transfers),
          account.currencyCode,
        ),
        currencyCode: baseCurrency,
      );
      if (classification == AccountClassification.asset) {
        assets.add(item);
      } else {
        liabilities.add(item);
      }
    }

    for (final loan in loans) {
      if (loan.isSettled) continue;
      final remaining = LoanBalanceCalculator.calculate(
        loan,
        payments,
      ).outstanding;
      if (remaining <= 0) continue;
      final item = NetWorthItem(
        id: 'loan:${loan.id}',
        name: loan.personName,
        type: loan.direction == LoanDirection.lent
            ? FinanceAccountType.loanGiven
            : FinanceAccountType.loanTaken,
        value: remaining,
        currencyCode: baseCurrency,
      );
      if (loan.direction == LoanDirection.lent) {
        assets.add(item);
      } else {
        liabilities.add(item);
      }
    }

    assets.sort((a, b) => b.value.compareTo(a.value));
    liabilities.sort((a, b) => b.value.compareTo(a.value));
    return NetWorthSnapshot(assets: assets, liabilities: liabilities);
  }
}
