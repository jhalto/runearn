import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/budgets/data/datasources/budget_local_data_source.dart';
import 'package:runearn/feature/budgets/data/datasources/budget_remote_data_source.dart';
import 'package:runearn/feature/budgets/data/models/budget_model.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    required this.network,
  });

  final BudgetLocalDataSource local;
  final BudgetRemoteDataSource remote;
  final FirebaseAuth auth;
  final NetworkInfo network;

  String get _userId {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<Budget>> getBudgets() async {
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
        .map((item) => BudgetModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget, _userId);
    await local.upsert({
      ...model.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    });
    await syncPending();
  }

  @override
  Future<void> deleteBudget(String id) async {
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
