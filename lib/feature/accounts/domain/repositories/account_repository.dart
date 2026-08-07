import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';

abstract interface class AccountRepository {
  Future<List<FinanceAccount>> getAccounts();
  Future<void> saveAccount(FinanceAccount account);
  Future<void> deleteAccount(String id);
  Future<void> syncPendingAccounts();
  Future<List<AccountTransfer>> getTransfers();
  Future<void> saveTransfer(AccountTransfer transfer);
  Future<void> deleteTransfer(String id);
}
