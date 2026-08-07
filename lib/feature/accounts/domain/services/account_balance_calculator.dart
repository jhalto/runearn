import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class AccountBalanceCalculator {
  const AccountBalanceCalculator._();

  static double calculate(
    FinanceAccount account,
    Iterable<Transaction> transactions, [
    Iterable<AccountTransfer> transfers = const [],
  ]) {
    var balance = account.balance;
    for (final transaction in transactions) {
      if (transaction.accountId != account.id) continue;
      final income = transaction.type == TransactionType.income;
      if (account.type.classification == AccountClassification.liability) {
        balance += income ? -transaction.amount : transaction.amount;
      } else {
        balance += income ? transaction.amount : -transaction.amount;
      }
    }
    final liability =
        account.type.classification == AccountClassification.liability;
    for (final transfer in transfers) {
      if (transfer.fromAccountId == account.id) {
        balance += liability ? transfer.amount : -transfer.amount;
      }
      if (transfer.toAccountId == account.id) {
        balance += liability
            ? -transfer.receivedAmount
            : transfer.receivedAmount;
      }
    }
    return balance;
  }
}
