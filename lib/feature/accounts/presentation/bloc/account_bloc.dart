import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/accounts/domain/repositories/account_repository.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this.repository) : super(const AccountInitial()) {
    on<LoadAccounts>((_, emit) => _load(emit));
    on<SaveAccountRequested>((event, emit) async {
      await _perform(() => repository.saveAccount(event.account), emit);
    });
    on<DeleteAccountRequested>((event, emit) async {
      await _perform(() => repository.deleteAccount(event.id), emit);
    });
    on<SaveTransferRequested>((event, emit) async {
      await _perform(() => repository.saveTransfer(event.transfer), emit);
    });
    on<DeleteTransferRequested>((event, emit) async {
      await _perform(() => repository.deleteTransfer(event.id), emit);
    });
    on<SyncAccountsRequested>((_, emit) async {
      await _perform(repository.syncPendingAccounts, emit);
    });
    on<ResetAccounts>((_, emit) {
      _loadRequested = false;
      emit(const AccountInitial());
    });
  }

  final AccountRepository repository;
  bool _loadRequested = false;

  void loadIfNeeded() {
    if (_loadRequested) return;
    _loadRequested = true;
    add(const LoadAccounts());
  }

  void resetForLogout() => add(const ResetAccounts());

  Future<void> _perform(
    Future<void> Function() operation,
    Emitter<AccountState> emit,
  ) async {
    try {
      await operation();
      await _load(emit);
    } catch (error) {
      emit(AccountFailure(error.toString()));
    }
  }

  Future<void> _load(Emitter<AccountState> emit) async {
    if (state is! AccountLoaded) emit(const AccountLoading());
    try {
      final accounts = await repository.getAccounts();
      final transfers = await repository.getTransfers();
      final next = AccountLoaded(accounts, transfers);
      if (state == next) return;
      emit(next);
    } catch (error) {
      _loadRequested = false;
      emit(AccountFailure(error.toString()));
    }
  }
}
