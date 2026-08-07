import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_event.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_state.dart';
import 'package:runearn/feature/recurring/domain/services/recurring_recording_service.dart';

class RecurringBloc extends Bloc<RecurringEvent, RecurringState> {
  RecurringBloc(this.repository, this.recordingService)
    : super(const RecurringInitial()) {
    on<LoadRecurring>((_, emit) => _load(emit));
    on<SaveRecurringRequested>(
      (event, emit) => _perform(() => repository.save(event.item), emit),
    );
    on<DeleteRecurringRequested>(
      (event, emit) => _perform(() => repository.delete(event.id), emit),
    );
    on<RecordRecurringRequested>(
      (event, emit) => _perform(
        () => recordingService.record(event.item, recordedAt: event.recordedAt),
        emit,
      ),
    );
    on<SyncRecurringRequested>(
      (_, emit) => _perform(repository.syncPending, emit),
    );
    on<ResetRecurring>((_, emit) {
      _loadRequested = false;
      emit(const RecurringInitial());
    });
  }

  final RecurringRepository repository;
  final RecurringRecordingService recordingService;
  bool _loadRequested = false;

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadRecurring());
  }

  void resetForLogout() => add(const ResetRecurring());

  Future<void> _perform(
    Future<void> Function() operation,
    Emitter<RecurringState> emit,
  ) async {
    try {
      await operation();
      await _load(emit);
    } catch (error) {
      emit(RecurringFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<RecurringState> emit) async {
    if (state is! RecurringLoaded) emit(const RecurringLoading());
    try {
      final next = RecurringLoaded(await repository.getRecurringTransactions());
      if (state != next) emit(next);
    } catch (error) {
      _loadRequested = false;
      emit(RecurringFailure(error.toString()));
    }
  }
}
