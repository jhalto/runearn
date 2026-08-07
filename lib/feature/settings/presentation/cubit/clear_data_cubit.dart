import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/loans/domain/usecases/clear_loans.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/usecases/clear_transactions_use_case.dart';

enum ClearDataTarget {
  loans,
  transactions,
  income,
  expenses;

  String get label => switch (this) {
    ClearDataTarget.loans => 'Loan records',
    ClearDataTarget.transactions => 'All transactions',
    ClearDataTarget.income => 'Income records',
    ClearDataTarget.expenses => 'Expense records',
  };

  String get confirmationPhrase => switch (this) {
    ClearDataTarget.loans => 'CLEAR LOANS',
    ClearDataTarget.transactions => 'CLEAR ALL TRANSACTIONS',
    ClearDataTarget.income => 'CLEAR INCOME',
    ClearDataTarget.expenses => 'CLEAR EXPENSES',
  };
}

sealed class ClearDataState extends Equatable {
  const ClearDataState();

  @override
  List<Object?> get props => const [];
}

final class ClearDataIdle extends ClearDataState {
  const ClearDataIdle();
}

final class ClearDataInProgress extends ClearDataState {
  final ClearDataTarget target;

  const ClearDataInProgress(this.target);

  @override
  List<Object?> get props => [target];
}

final class ClearDataSucceeded extends ClearDataState {
  final ClearDataTarget target;

  const ClearDataSucceeded(this.target);

  @override
  List<Object?> get props => [target];
}

final class ClearDataFailed extends ClearDataState {
  final ClearDataTarget target;
  final String message;

  const ClearDataFailed(this.target, this.message);

  @override
  List<Object?> get props => [target, message];
}

class ClearDataCubit extends Cubit<ClearDataState> {
  final ClearLoans clearLoans;
  final ClearTransactionsUseCase clearTransactions;

  ClearDataCubit({required this.clearLoans, required this.clearTransactions})
    : super(const ClearDataIdle());

  Future<void> clear(ClearDataTarget target) async {
    if (state is ClearDataInProgress) return;
    emit(ClearDataInProgress(target));
    try {
      switch (target) {
        case ClearDataTarget.loans:
          await clearLoans();
        case ClearDataTarget.transactions:
          await clearTransactions();
        case ClearDataTarget.income:
          await clearTransactions(type: TransactionType.income);
        case ClearDataTarget.expenses:
          await clearTransactions(type: TransactionType.expense);
      }
      emit(ClearDataSucceeded(target));
    } catch (error) {
      emit(ClearDataFailed(target, error.toString()));
    }
  }
}
