import 'package:equatable/equatable.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';

class TourSummary extends Equatable {
  TourSummary({
    required this.tour,
    required List<TourCollection> collections,
    required List<TourExpense> expenses,
  }) : collections = List.unmodifiable(collections),
       expenses = List.unmodifiable(expenses);

  final Tour tour;
  final List<TourCollection> collections;
  final List<TourExpense> expenses;

  double get totalCollected =>
      collections.fold(0, (total, item) => total + item.amount);
  double get totalExpenses =>
      expenses.fold(0, (total, item) => total + item.amount);
  double get availableCash => totalCollected - totalExpenses;
  double get budgetRemaining => tour.budget - totalExpenses;
  double get budgetUsed => tour.budget <= 0
      ? 0
      : (totalExpenses / tour.budget).clamp(0, double.infinity);

  @override
  List<Object?> get props => [tour, collections, expenses];
}
