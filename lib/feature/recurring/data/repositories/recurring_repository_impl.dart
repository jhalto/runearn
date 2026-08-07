import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/recurring/data/datasources/recurring_local_data_source.dart';
import 'package:runearn/feature/recurring/data/datasources/recurring_remote_data_source.dart';
import 'package:runearn/feature/recurring/data/models/recurring_transaction_model.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  const RecurringRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    required this.network,
  });
  final RecurringLocalDataSource local;
  final RecurringRemoteDataSource remote;
  final FirebaseAuth auth;
  final NetworkInfo network;

  String get _userId {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final userId = _userId;
    if (await network.isConnected) {
      try {
        await syncPending();
        final pending = (await local.getPending(
          userId,
        )).map((item) => item['id']).toSet();
        for (final item in await remote.getAll()) {
          if (pending.contains(item['id'])) continue;
          await local.upsert({...item, 'userId': userId, 'isSynced': 1});
        }
      } catch (_) {}
    }
    return (await local.getAll(userId))
        .map((item) => RecurringTransactionModel(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> save(RecurringTransaction item) async {
    await local.upsert({
      ...RecurringTransactionModel.fromEntity(item, _userId).toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    });
    await syncPending();
  }

  @override
  Future<void> delete(String id) async {
    await local.softDelete(id, _userId);
    await syncPending();
  }

  @override
  Future<void> syncPending() async {
    if (!await network.isConnected) return;
    final userId = _userId;
    for (final item in await local.getPending(userId)) {
      try {
        await remote.upsert({...item, 'isSynced': null});
        await local.markSynced(item['id'] as String, userId);
      } catch (_) {}
    }
  }
}
