import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/search/data/saved_filter_store.dart';
import 'package:runearn/feature/search/domain/entities/saved_transaction_filter.dart';
import 'package:runearn/feature/search/domain/entities/transaction_filter.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';

class TransactionSearchState extends Equatable {
  const TransactionSearchState({
    this.filter = const TransactionFilter(),
    this.results = const [],
    this.savedFilters = const [],
    this.isLoadingSavedFilters = true,
    this.message,
  });

  final TransactionFilter filter;
  final List<Transaction> results;
  final List<SavedTransactionFilter> savedFilters;
  final bool isLoadingSavedFilters;
  final String? message;

  double get total => results.fold(0, (sum, item) => sum + item.amount);

  TransactionSearchState copyWith({
    TransactionFilter? filter,
    List<Transaction>? results,
    List<SavedTransactionFilter>? savedFilters,
    bool? isLoadingSavedFilters,
    String? message,
    bool clearMessage = false,
  }) => TransactionSearchState(
    filter: filter ?? this.filter,
    results: results ?? this.results,
    savedFilters: savedFilters ?? this.savedFilters,
    isLoadingSavedFilters: isLoadingSavedFilters ?? this.isLoadingSavedFilters,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    filter,
    results,
    savedFilters,
    isLoadingSavedFilters,
    message,
  ];
}

class TransactionSearchCubit extends Cubit<TransactionSearchState> {
  TransactionSearchCubit(this._store) : super(const TransactionSearchState());

  final SavedFilterStore _store;
  List<Transaction> _source = const [];

  Future<void> initialize(List<Transaction> transactions) async {
    _source = List.unmodifiable(transactions);
    final saved = await _store.load();
    if (isClosed) return;
    emit(
      state.copyWith(
        results: state.filter.apply(_source),
        savedFilters: saved,
        isLoadingSavedFilters: false,
      ),
    );
  }

  void setTransactions(List<Transaction> transactions) {
    if (_source == transactions) return;
    _source = List.unmodifiable(transactions);
    _apply(state.filter);
  }

  void updateFilter(TransactionFilter filter) => _apply(filter);

  void updateQuery(String query) => _apply(state.filter.copyWith(query: query));

  void clear() => _apply(const TransactionFilter());

  void applySaved(SavedTransactionFilter saved) => _apply(saved.filter);

  Future<void> saveCurrent(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final item = SavedTransactionFilter(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
      filter: state.filter.copyWith(query: ''),
      createdAt: DateTime.now(),
    );
    final updated = [...state.savedFilters, item];
    await _store.save(updated);
    if (!isClosed) {
      emit(state.copyWith(savedFilters: updated, message: 'Filter saved.'));
    }
  }

  Future<void> deleteSaved(String id) async {
    final updated = state.savedFilters
        .where((item) => item.id != id)
        .toList(growable: false);
    await _store.save(updated);
    if (!isClosed) {
      emit(state.copyWith(savedFilters: updated, message: 'Filter deleted.'));
    }
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  void _apply(TransactionFilter filter) {
    final next = state.copyWith(
      filter: filter,
      results: filter.apply(_source),
      clearMessage: true,
    );
    if (next != state) emit(next);
  }
}
