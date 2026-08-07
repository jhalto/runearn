import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';

abstract interface class TourRepository {
  Future<List<Tour>> getTours();
  Future<List<TourCollection>> getCollections();
  Future<List<TourExpense>> getExpenses();
  Future<void> saveTour(Tour tour);
  Future<void> deleteTour(String id);
  Future<void> saveCollection(TourCollection collection);
  Future<void> deleteCollection(String id);
  Future<void> saveExpense(TourExpense expense);
  Future<void> deleteExpense(String id);
  Future<void> syncPending();
}
