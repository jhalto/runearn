import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/transactions/domain/usecases/detete_transaction_use_case.dart';
import 'package:runearn/feature/transactions/domain/usecases/sync_pending_trasaction_use_case.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';
import 'package:runearn/feature/transactions/domain/usecases/update_transaction_use_case.dart';

import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final SyncPendingTransactionsUseCase syncPendingTransactionsUseCase;
  bool _loadRequested = false;

  TransactionBloc(
    this.repository, {
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.syncPendingTransactionsUseCase,
  }) : super(const TransactionLoading()) {
    on<LoadTransactions>((event, emit) async {
      await _loadTransactions(emit);
    });
    on<ResetTransactions>((event, emit) {
      _loadRequested = false;
      emit(const TransactionLoading());
    });

    on<AddTransactionEvent>((event, emit) async {
      await _runTransactionOperation(
        () => repository.addTransaction(event.transaction),
        emit,
      );
    });

    on<DeleteTransactionEvent>((event, emit) async {
      await _runTransactionOperation(
        () => deleteTransactionUseCase(event.id),
        emit,
      );
    });

    on<UpdateTransactionEvent>((event, emit) async {
      await _runTransactionOperation(
        () => updateTransactionUseCase(event.transaction),
        emit,
      );
    });

    on<SyncPendingTransactionsEvent>((event, emit) async {
      final currentState = state;

      if (currentState is TransactionLoaded) {
        emit(
          TransactionSyncing(
            transactions: currentState.transactions,
            analytics: currentState.analytics,
          ),
        );
      } else {
        emit(const TransactionLoading());
      }

      try {
        await syncPendingTransactionsUseCase();

        final data = await repository.getTransactions();
        final analytics = TransactionAnalytics(data);

        emit(TransactionLoaded(transactions: data, analytics: analytics));
      } catch (e) {
        if (currentState is TransactionLoaded) {
          emit(currentState);
        } else {
          emit(TransactionError(e.toString()));
        }
      }
    });
  }

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadTransactions());
  }

  void resetForLogout() {
    _loadRequested = false;
    add(const ResetTransactions());
  }

  Future<void> _loadTransactions(Emitter<TransactionState> emit) async {
    try {
      final data = await repository.getTransactions();
      final analytics = TransactionAnalytics(data);
      final nextState = TransactionLoaded(
        transactions: data,
        analytics: analytics,
      );

      if (state is TransactionLoaded && state == nextState) return;
      emit(nextState);
    } catch (error) {
      _loadRequested = false;
      emit(TransactionError(_errorMessage(error)));
    }
  }

  Future<void> _runTransactionOperation(
    Future<void> Function() operation,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await operation();
      await _loadTransactions(emit);
    } catch (error) {
      emit(TransactionError(_errorMessage(error)));
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    if (message.contains('User not logged in') ||
        message.contains('not authenticated')) {
      return 'Your session has expired. Please sign in again.';
    }
    return message;
  }
}
