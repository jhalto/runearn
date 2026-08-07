import 'package:intl/intl.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class TransactionAnalytics {
  final List<Transaction> transactions;

  TransactionAnalytics(this.transactions);

  // 💰 TOTALS
  double get totalIncome => _sum(TransactionType.income);

  double get totalExpense => _sum(TransactionType.expense);

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
        for (final allocation in t.categoryAllocations) {
          final key = allocation.categoryName;
          result[key] = (result[key] ?? 0) + allocation.amount;
        }
      }
    }

    return result;
  }

  // 📆 DAILY
  List<TimeGroup> daily() {
    return _groupBy((date) => DateFormat('yyyy-MM-dd').format(date));
  }

  // 📅 MONTHLY
  List<TimeGroup> monthly() {
    return _groupBy((date) => DateFormat('yyyy-MM').format(date));
  }

  // 📆 WEEKLY
  List<TimeGroup> weekly() {
    return _groupBy((date) => _weekKey(date));
  }

  // 📊 YEARLY
  List<TimeGroup> yearly() {
    return _groupBy((date) => DateFormat('yyyy').format(date));
  }

  // 🔥 CORE ENGINE
  List<TimeGroup> _groupBy(String Function(DateTime) keyBuilder) {
    final Map<String, TimeGroup> map = {};

    for (final t in transactions) {
      final key = keyBuilder(t.date);

      map.putIfAbsent(key, () => TimeGroup(label: key));

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
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final thursday = normalizedDate.add(
      Duration(days: 4 - normalizedDate.weekday),
    );

    final weekYear = thursday.year;

    final firstThursday = DateTime(
      weekYear,
      1,
      4,
    ).add(Duration(days: 4 - DateTime(weekYear, 1, 4).weekday));

    final weekNumber = 1 + (thursday.difference(firstThursday).inDays ~/ 7);

    return '$weekYear-W${weekNumber.toString().padLeft(2, '0')}';
  }

  // 🌟 TODAY OVERVIEW
  TimeGroup todayOverview() {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayData = daily().where((item) => item.label == todayKey).toList();

    if (todayData.isEmpty) {
      return TimeGroup(label: todayKey);
    }

    return todayData.first;
  }
}

// 📦 Generic Time Group Model
class TimeGroup {
  final String label;
  double income;
  double expense;

  TimeGroup({required this.label, this.income = 0, this.expense = 0});

  double get balance => income - expense;
}
