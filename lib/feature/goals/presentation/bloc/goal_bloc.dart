import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/goals/domain/repositories/goal_repository.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_event.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_state.dart';
import 'package:runearn/feature/goals/domain/services/goal_funding_service.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc(this.repository, this.fundingService) : super(const GoalInitial()) {
    on<LoadGoals>((_, emit) => _load(emit));
    on<SaveGoalRequested>(
      (event, emit) => _perform(() => repository.saveGoal(event.goal), emit),
    );
    on<DeleteGoalRequested>(
      (event, emit) =>
          _perform(() => fundingService.deleteGoal(event.id), emit),
    );
    on<AddGoalContributionRequested>(
      (event, emit) => _perform(
        () => fundingService.contribute(
          goal: event.goal,
          contribution: event.contribution,
        ),
        emit,
      ),
    );
    on<DeleteGoalContributionRequested>(
      (event, emit) => _perform(
        () => fundingService.deleteContribution(event.contribution),
        emit,
      ),
    );
    on<SyncGoalsRequested>((_, emit) => _perform(repository.syncPending, emit));
    on<ResetGoals>((_, emit) {
      _loadRequested = false;
      emit(const GoalInitial());
    });
  }

  final GoalRepository repository;
  final GoalFundingService fundingService;
  bool _loadRequested = false;

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadGoals());
  }

  void resetForLogout() => add(const ResetGoals());

  Future<void> _perform(
    Future<void> Function() operation,
    Emitter<GoalState> emit,
  ) async {
    try {
      await operation();
      await _load(emit);
    } catch (error) {
      emit(GoalFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<GoalState> emit) async {
    if (state is! GoalLoaded) emit(const GoalLoading());
    try {
      final goals = await repository.getGoals();
      final contributions = await repository.getContributions();
      final next = GoalLoaded(goals, contributions);
      if (state != next) emit(next);
    } catch (error) {
      _loadRequested = false;
      emit(GoalFailure(error.toString()));
    }
  }
}
