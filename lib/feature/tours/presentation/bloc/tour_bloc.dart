import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/tours/domain/repositories/tour_repository.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';

class TourBloc extends Bloc<TourEvent, TourState> {
  TourBloc(this.repository) : super(const TourInitial()) {
    on<LoadTours>((_, emit) => _load(emit));
    on<SaveTourRequested>(
      (event, emit) => _perform(() => repository.saveTour(event.tour), emit),
    );
    on<DeleteTourRequested>(
      (event, emit) => _perform(() => repository.deleteTour(event.id), emit),
    );
    on<SaveTourCollectionRequested>(
      (event, emit) =>
          _perform(() => repository.saveCollection(event.collection), emit),
    );
    on<DeleteTourCollectionRequested>(
      (event, emit) =>
          _perform(() => repository.deleteCollection(event.id), emit),
    );
    on<SaveTourExpenseRequested>(
      (event, emit) =>
          _perform(() => repository.saveExpense(event.expense), emit),
    );
    on<DeleteTourExpenseRequested>(
      (event, emit) => _perform(() => repository.deleteExpense(event.id), emit),
    );
    on<SyncToursRequested>((_, emit) => _perform(repository.syncPending, emit));
    on<ResetTours>((_, emit) {
      _loadRequested = false;
      emit(const TourInitial());
    });
  }

  final TourRepository repository;
  bool _loadRequested = false;

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadTours());
  }

  void resetForLogout() => add(const ResetTours());

  Future<void> _perform(
    Future<void> Function() operation,
    Emitter<TourState> emit,
  ) async {
    try {
      await operation();
      await _load(emit);
    } catch (error) {
      emit(TourFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<TourState> emit) async {
    if (state is! TourLoaded) emit(const TourLoading());
    try {
      final next = TourLoaded(
        tours: await repository.getTours(),
        collections: await repository.getCollections(),
        expenses: await repository.getExpenses(),
      );
      if (state != next) emit(next);
    } catch (error) {
      _loadRequested = false;
      emit(TourFailure(error.toString()));
    }
  }
}
