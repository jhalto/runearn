import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/recurring/domain/services/recurrence_calculator.dart';

void main() {
  test('monthly recurrence safely handles the end of a month', () {
    expect(
      RecurrenceCalculator.next(
        DateTime(2026, 1, 31),
        RecurrenceFrequency.monthly,
      ),
      DateTime(2026, 2, 28),
    );
  });

  test('yearly recurrence safely handles leap day', () {
    expect(
      RecurrenceCalculator.next(
        DateTime(2024, 2, 29),
        RecurrenceFrequency.yearly,
      ),
      DateTime(2025, 2, 28),
    );
  });

  test('advances an overdue schedule beyond completion date', () {
    expect(
      RecurrenceCalculator.advancePast(
        DateTime(2026, 4, 15),
        RecurrenceFrequency.monthly,
        DateTime(2026, 7, 28),
      ),
      DateTime(2026, 8, 15),
    );
  });
}
