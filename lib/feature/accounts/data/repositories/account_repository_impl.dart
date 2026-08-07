import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/accounts/data/datasources/account_local_data_source.dart';
import 'package:runearn/feature/accounts/data/datasources/account_remote_data_source.dart';
import 'package:runearn/feature/accounts/data/models/account_model.dart';
import 'package:runearn/feature/accounts/data/models/account_transfer_model.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    required this.network,
  });

  final AccountLocalDataSource local;
  final AccountRemoteDataSource remote;
  final FirebaseAuth auth;
  final NetworkInfo network;

  String get _userId {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<FinanceAccount>> getAccounts() async {
    final userId = _userId;
    if (await network.isConnected) {
      try {
        await syncPendingAccounts();
        final pendingIds = (await local.getPending(
          userId,
        )).map((item) => item['id']).toSet();
        for (final item in await remote.getAll()) {
          if (pendingIds.contains(item['id'])) continue;
          await local.upsert({...item, 'userId': userId, 'isSynced': 1});
        }
      } catch (_) {}
    }
    return (await local.getAll(userId))
        .map((item) => AccountModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    final userId = _userId;
    final model = AccountModel.fromEntity(account, userId: userId);
    final data = {
      ...model.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    };
    await local.upsert(data);
    if (await network.isConnected) {
      try {
        await remote.upsert({...data, 'isSynced': null});
        await local.markSynced(account.id, userId);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    await local.softDelete(id, _userId);
    await syncPendingAccounts();
  }

  @override
  Future<void> syncPendingAccounts() async {
    if (!await network.isConnected) return;
    final userId = _userId;
    for (final item in await local.getPending(userId)) {
      try {
        await remote.upsert({...item, 'isSynced': null});
        await local.markSynced(item['id'] as String, userId);
      } catch (_) {}
    }
    for (final item in await local.getPendingTransfers(userId)) {
      try {
        await remote.upsertTransfer({...item, 'isSynced': null});
        await local.markTransferSynced(item['id'] as String, userId);
      } catch (_) {}
    }
  }

  @override
  Future<List<AccountTransfer>> getTransfers() async {
    final userId = _userId;
    if (await network.isConnected) {
      try {
        await syncPendingAccounts();
        final pendingIds = (await local.getPendingTransfers(
          userId,
        )).map((item) => item['id']).toSet();
        for (final item in await remote.getTransfers()) {
          if (pendingIds.contains(item['id'])) continue;
          await local.upsertTransfer({
            ...item,
            'userId': userId,
            'isSynced': 1,
          });
        }
      } catch (_) {}
    }
    return (await local.getTransfers(userId))
        .map((item) => AccountTransferModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveTransfer(AccountTransfer transfer) async {
    if (transfer.fromAccountId == transfer.toAccountId) {
      throw ArgumentError('Source and destination accounts must differ');
    }
    final userId = _userId;
    final model = AccountTransferModel.fromEntity(transfer, userId: userId);
    final data = {
      ...model.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    };
    await local.upsertTransfer(data);
    await syncPendingAccounts();
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await local.deleteTransfer(id, _userId);
    await syncPendingAccounts();
  }
}
