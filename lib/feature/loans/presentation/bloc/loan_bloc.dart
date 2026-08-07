import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/loans/domain/usecases/add_loan.dart';
import 'package:runearn/feature/loans/domain/usecases/delete_loan.dart';
import 'package:runearn/feature/loans/domain/usecases/get_loans.dart';
import 'package:runearn/feature/loans/domain/usecases/sync_pending_loans.dart';
import 'package:runearn/feature/loans/domain/usecases/update_loan.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final GetLoans getLoans;
  final AddLoan addLoan;
  final UpdateLoan updateLoan;
  final DeleteLoan deleteLoan;
  final SyncPendingLoans syncPendingLoans;
  final LoanRepository repository;
  bool _loadRequested = false;

  LoanBloc({
    required this.getLoans,
    required this.addLoan,
    required this.updateLoan,
    required this.deleteLoan,
    required this.syncPendingLoans,
    required this.repository,
  }) : super(const LoanInitial()) {
    on<LoadLoans>(_onLoad);
    on<ResetLoans>(_onReset);
    on<SyncPendingLoansRequested>(_onSyncPending);
    on<AddLoanRequested>(_onAdd);
    on<UpdateLoanRequested>(_onUpdate);
    on<LoanSettlementChanged>(_onSettlementChanged);
    on<DeleteLoanRequested>(_onDelete);
    on<AddLoanPaymentRequested>(_onAddPayment);
    on<DeleteLoanPaymentRequested>(_onDeletePayment);
  }

  Future<void> _onLoad(LoadLoans event, Emitter<LoanState> emit) async {
    if (state is! LoanLoaded) {
      emit(const LoanLoading());
    }
    await _load(emit);
  }

  void _onReset(ResetLoans event, Emitter<LoanState> emit) {
    _loadRequested = false;
    emit(const LoanInitial());
  }

  Future<void> _onSyncPending(
    SyncPendingLoansRequested event,
    Emitter<LoanState> emit,
  ) async {
    try {
      await syncPendingLoans();
      await _load(emit);
    } catch (error) {
      // Keep the currently displayed local state. A later connectivity event
      // or manual refresh will retry pending records.
      if (state is! LoanLoaded) {
        emit(LoanFailure(error.toString()));
      }
    }
  }

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadLoans());
  }

  void resetForLogout() {
    _loadRequested = false;
    add(const ResetLoans());
  }

  Future<void> _onAdd(AddLoanRequested event, Emitter<LoanState> emit) async {
    await _perform(() => addLoan(event.loan), emit);
  }

  Future<void> _onUpdate(
    UpdateLoanRequested event,
    Emitter<LoanState> emit,
  ) async {
    await _perform(() => updateLoan(event.loan), emit);
  }

  Future<void> _onSettlementChanged(
    LoanSettlementChanged event,
    Emitter<LoanState> emit,
  ) async {
    await _perform(
      () => updateLoan(event.loan.copyWith(isSettled: !event.loan.isSettled)),
      emit,
    );
  }

  Future<void> _onDelete(
    DeleteLoanRequested event,
    Emitter<LoanState> emit,
  ) async {
    await _perform(() => deleteLoan(event.id), emit);
  }

  Future<void> _onAddPayment(
    AddLoanPaymentRequested event,
    Emitter<LoanState> emit,
  ) async {
    final current = state;
    if (current is! LoanLoaded) return;
    final loan = current.loans
        .where((item) => item.id == event.payment.loanId)
        .firstOrNull;
    if (loan == null) return;
    final remaining = current.remainingFor(loan);
    if (event.payment.amount <= 0 || event.payment.amount > remaining) {
      emit(const LoanFailure('Payment cannot exceed the remaining balance.'));
      return;
    }
    await _perform(() async {
      await repository.savePayment(event.payment);
      if (event.payment.amount >= remaining) {
        await updateLoan(loan.copyWith(isSettled: true));
      }
    }, emit);
  }

  Future<void> _onDeletePayment(
    DeleteLoanPaymentRequested event,
    Emitter<LoanState> emit,
  ) async {
    final current = state;
    final loan = current is LoanLoaded
        ? current.loans
              .where((item) => item.id == event.payment.loanId)
              .firstOrNull
        : null;
    await _perform(() async {
      await repository.deletePayment(event.payment.id);
      if (loan?.isSettled == true) {
        await updateLoan(loan!.copyWith(isSettled: false));
      }
    }, emit);
  }

  Future<void> _perform(
    Future<void> Function() operation,
    Emitter<LoanState> emit,
  ) async {
    try {
      await operation();
      await _load(emit);
    } catch (error) {
      emit(LoanFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<LoanState> emit) async {
    try {
      final loans = await getLoans();
      final payments = await repository.getPayments();
      final nextState = LoanLoaded(loans, payments);
      if (state is LoanLoaded && state == nextState) return;
      emit(nextState);
    } catch (error) {
      _loadRequested = false;
      emit(LoanFailure(error.toString()));
    }
  }
}
