import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';

sealed class AccountState extends Equatable {
  const AccountState();
  @override
  List<Object?> get props => const [];
}

final class AccountInitial extends AccountState {
  const AccountInitial();
}

final class AccountLoading extends AccountState {
  const AccountLoading();
}

final class AccountLoaded extends AccountState {
  AccountLoaded(List<FinanceAccount> accounts, List<AccountTransfer> transfers)
    : accounts = List.unmodifiable(accounts),
      transfers = List.unmodifiable(transfers);
  final List<FinanceAccount> accounts;
  final List<AccountTransfer> transfers;

  double totalFor(AccountClassification classification) => accounts
      .where((account) => account.type.classification == classification)
      .fold(0, (total, account) => total + account.balance);

  double get netWorth =>
      totalFor(AccountClassification.asset) -
      totalFor(AccountClassification.liability);

  @override
  List<Object?> get props => [accounts, transfers];
}

final class AccountFailure extends AccountState {
  const AccountFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
