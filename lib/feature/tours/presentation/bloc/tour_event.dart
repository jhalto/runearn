import 'package:equatable/equatable.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';

sealed class TourEvent extends Equatable {
  const TourEvent();
  @override
  List<Object?> get props => const [];
}

final class LoadTours extends TourEvent {
  const LoadTours();
}

final class SaveTourRequested extends TourEvent {
  const SaveTourRequested(this.tour);
  final Tour tour;
  @override
  List<Object?> get props => [tour];
}

final class DeleteTourRequested extends TourEvent {
  const DeleteTourRequested(this.id);
  final String id;
}

final class SaveTourCollectionRequested extends TourEvent {
  const SaveTourCollectionRequested(this.collection);
  final TourCollection collection;
  @override
  List<Object?> get props => [collection];
}

final class DeleteTourCollectionRequested extends TourEvent {
  const DeleteTourCollectionRequested(this.id);
  final String id;
}

final class SaveTourExpenseRequested extends TourEvent {
  const SaveTourExpenseRequested(this.expense);
  final TourExpense expense;
  @override
  List<Object?> get props => [expense];
}

final class DeleteTourExpenseRequested extends TourEvent {
  const DeleteTourExpenseRequested(this.id);
  final String id;
}

final class SyncToursRequested extends TourEvent {
  const SyncToursRequested();
}

final class ResetTours extends TourEvent {
  const ResetTours();
}
