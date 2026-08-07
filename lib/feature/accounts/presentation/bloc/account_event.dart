import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();
  @override
  List<Object?> get props => const [];
}

final class LoadAccounts extends AccountEvent {
  const LoadAccounts();
}

final class SaveAccountRequested extends AccountEvent {
  const SaveAccountRequested(this.account);
  final FinanceAccount account;
  @override
  List<Object?> get props => [account];
}

final class DeleteAccountRequested extends AccountEvent {
  const DeleteAccountRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class SyncAccountsRequested extends AccountEvent {
  const SyncAccountsRequested();
}

final class ResetAccounts extends AccountEvent {
  const ResetAccounts();
}

final class SaveTransferRequested extends AccountEvent {
  const SaveTransferRequested(this.transfer);
  final AccountTransfer transfer;
  @override
  List<Object?> get props => [transfer];
}

final class DeleteTransferRequested extends AccountEvent {
  const DeleteTransferRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
