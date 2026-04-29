import 'package:intl/intl.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';


class MonthlyAnalytics {
  final String month; // e.g. "2026-01"
  final double income;
  final double expense;

  MonthlyAnalytics({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}


class MonthlyAnalyticsBuilder {
  static List<MonthlyAnalytics> build(List<Transaction> transactions) {
    final Map<String, _MonthlyTemp> temp = {};

    for (final t in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.date);

      temp.putIfAbsent(monthKey, () => _MonthlyTemp());

      if (t.type == TransactionType.income) {
        temp[monthKey]!.income += t.amount;
      } else {
        temp[monthKey]!.expense += t.amount;
      }
    }

    return temp.entries.map((e) {
      return MonthlyAnalytics(
        month: e.key,
        income: e.value.income,
        expense: e.value.expense,
      );
    }).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
  }
}

class _MonthlyTemp {
  double income = 0;
  double expense = 0;
}