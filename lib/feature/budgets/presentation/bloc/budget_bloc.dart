import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/budgets/domain/repositories/budget_repository.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_event.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc(this.repository) : super(const BudgetInitial()) {
    on<LoadBudgets>((_, emit) => _load(emit));
    on<SaveBudgetRequested>(
      (event, emit) =>
          _perform(() => repository.saveBudget(event.budget), emit),
    );
    on<DeleteBudgetRequested>(
      (event, emit) => _perform(() => repository.deleteBudget(event.id), emit),
    );
    on<SyncBudgetsRequested>(
      (_, emit) => _perform(repository.syncPending, emit),
    );
    on<ResetBudgets>((_, emit) {
      _loadRequested = false;
      emit(const BudgetInitial());
    });
  }

  final BudgetRepository repository;
  bool _loadRequested = false;

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadBudgets());
  }

  void resetForLogout() => add(const ResetBudgets());

  Future<void> _perform(
    Future<void> Function() action,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await action();
      await _load(emit);
    } catch (error) {
      emit(BudgetFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<BudgetState> emit) async {
    if (state is! BudgetLoaded) emit(const BudgetLoading());
    try {
      final next = BudgetLoaded(await repository.getBudgets());
      if (state != next) emit(next);
    } catch (error) {
      _loadRequested = false;
      emit(BudgetFailure(error.toString()));
    }
  }
}
