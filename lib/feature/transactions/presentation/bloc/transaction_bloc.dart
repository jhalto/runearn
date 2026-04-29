import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';

import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc(this.repository) : super(TransactionLoading()) {
    on<LoadTransactions>((event, emit) async {
      emit(TransactionLoading());

      final data = await repository.getTransactions();

      final analytics = TransactionAnalytics(data);

      emit(TransactionLoaded(transactions: data, analytics: analytics));
    });

    on<AddTransactionEvent>((event, emit) async {
      await repository.addTransaction(event.transaction);

      final data = await repository.getTransactions();
      final analytics = TransactionAnalytics(data);

      emit(TransactionLoaded(transactions: data, analytics: analytics));
    });

    on<DeleteTransactionEvent>((event, emit) async {
      await repository.deleteTransaction(event.id);

      final data = await repository.getTransactions();
      final analytics = TransactionAnalytics(data);

      emit(TransactionLoaded(transactions: data, analytics: analytics));
    });
  }
}
