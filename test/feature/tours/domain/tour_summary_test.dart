import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';
import 'package:runearn/feature/tours/domain/entities/tour_summary.dart';

void main() {
  test('derives tour cash and budget position from ledgers', () {
    final now = DateTime(2026, 7, 28);
    final summary = TourSummary(
      tour: Tour(
        id: 'tour-1',
        name: 'Cox’s Bazar',
        destination: 'Cox’s Bazar',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        budget: 10000,
        status: TourStatus.planned,
      ),
      collections: [
        TourCollection(
          id: 'collection-1',
          tourId: 'tour-1',
          memberName: 'A',
          amount: 6000,
          date: now,
        ),
        TourCollection(
          id: 'collection-2',
          tourId: 'tour-1',
          memberName: 'B',
          amount: 4000,
          date: now,
        ),
      ],
      expenses: [
        TourExpense(
          id: 'expense-1',
          tourId: 'tour-1',
          title: 'Bus',
          category: 'Transport',
          amount: 3500,
          date: now,
        ),
        TourExpense(
          id: 'expense-2',
          tourId: 'tour-1',
          title: 'Hotel',
          category: 'Accommodation',
          amount: 2500,
          date: now,
        ),
      ],
    );

    expect(summary.totalCollected, 10000);
    expect(summary.totalExpenses, 6000);
    expect(summary.availableCash, 4000);
    expect(summary.budgetRemaining, 4000);
    expect(summary.budgetUsed, .6);
  });
}
