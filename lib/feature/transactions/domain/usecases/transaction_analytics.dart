import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class TransactionAnalytics {
  final List<Transaction> transactions;

  TransactionAnalytics(this.transactions);

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  Map<String, double> expenseByCategory() {
    final Map<String, double> result = {};

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        final key = t.category.name;
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }

    return result;
  }

  Map<String, double> incomeByCategory() {
    final Map<String, double> result = {};

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        final key = t.category.name;
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }

    return result;
  }
}
