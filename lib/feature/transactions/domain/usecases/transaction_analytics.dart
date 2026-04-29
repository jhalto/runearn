import 'package:intl/intl.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class TransactionAnalytics {
  final List<Transaction> transactions;

  TransactionAnalytics(this.transactions);

  // 💰 TOTALS
  double get totalIncome =>
      _sum(TransactionType.income);

  double get totalExpense =>
      _sum(TransactionType.expense);

  double get balance => totalIncome - totalExpense;

  double _sum(TransactionType type) {
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // 📊 CATEGORY ANALYTICS
  Map<String, double> byCategory(TransactionType type) {
    final Map<String, double> result = {};

    for (final t in transactions) {
      if (t.type == type) {
        final key = t.category.name;
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }

    return result;
  }

  // 📅 MONTHLY
  List<_TimeGroup> monthly() {
    return _groupBy((date) => DateFormat('yyyy-MM').format(date));
  }

  // 📆 WEEKLY
  List<_TimeGroup> weekly() {
    return _groupBy((date) => _weekKey(date));
  }

  // 📊 YEARLY
  List<_TimeGroup> yearly() {
    return _groupBy((date) => DateFormat('yyyy').format(date));
  }

  // 🔥 CORE ENGINE (REUSABLE)
  List<_TimeGroup> _groupBy(String Function(DateTime) keyBuilder) {
    final Map<String, _TimeGroup> map = {};

    for (final t in transactions) {
      final key = keyBuilder(t.date);

      map.putIfAbsent(key, () => _TimeGroup(label: key));

      if (t.type == TransactionType.income) {
        map[key]!.income += t.amount;
      } else {
        map[key]!.expense += t.amount;
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => b.label.compareTo(a.label));
    return list;
  }

  String _weekKey(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final week = date.difference(startOfYear).inDays ~/ 7 + 1;
    return "${date.year}-W$week";
  }
}

// 📦 Generic Time Group Model
class _TimeGroup {
  final String label;
  double income;
  double expense;

  _TimeGroup({
    required this.label,
    this.income = 0,
    this.expense = 0,
  });

  double get balance => income - expense;
}