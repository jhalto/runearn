import 'package:equatable/equatable.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';
import 'package:runearn/feature/tours/domain/entities/tour_summary.dart';

sealed class TourState extends Equatable {
  const TourState();
  @override
  List<Object?> get props => const [];
}

final class TourInitial extends TourState {
  const TourInitial();
}

final class TourLoading extends TourState {
  const TourLoading();
}

final class TourLoaded extends TourState {
  TourLoaded({
    required List<Tour> tours,
    required List<TourCollection> collections,
    required List<TourExpense> expenses,
  }) : tours = List.unmodifiable(tours),
       collections = List.unmodifiable(collections),
       expenses = List.unmodifiable(expenses);

  final List<Tour> tours;
  final List<TourCollection> collections;
  final List<TourExpense> expenses;

  TourSummary summaryFor(Tour tour) => TourSummary(
    tour: tour,
    collections: collections
        .where((item) => item.tourId == tour.id)
        .toList(growable: false),
    expenses: expenses
        .where((item) => item.tourId == tour.id)
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [tours, collections, expenses];
}

final class TourFailure extends TourState {
  const TourFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
