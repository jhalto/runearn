import 'dart:math';

import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';

class RecurrenceCalculator {
  const RecurrenceCalculator._();

  static DateTime next(
    DateTime date,
    RecurrenceFrequency frequency,
  ) => switch (frequency) {
    RecurrenceFrequency.daily => DateTime(date.year, date.month, date.day + 1),
    RecurrenceFrequency.weekly => DateTime(date.year, date.month, date.day + 7),
    RecurrenceFrequency.monthly => _addMonths(date, 1),
    RecurrenceFrequency.yearly => _addMonths(date, 12),
  };

  static DateTime advancePast(
    DateTime due,
    RecurrenceFrequency frequency,
    DateTime completedAt,
  ) {
    var result = next(due, frequency);
    while (!result.isAfter(completedAt)) {
      result = next(result, frequency);
    }
    return result;
  }

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      min(date.day, lastDay),
      date.hour,
      date.minute,
    );
  }
}
