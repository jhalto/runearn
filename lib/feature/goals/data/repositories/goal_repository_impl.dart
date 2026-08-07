import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/goals/data/datasources/goal_local_data_source.dart';
import 'package:runearn/feature/goals/data/datasources/goal_remote_data_source.dart';
import 'package:runearn/feature/goals/data/models/goal_contribution_model.dart';
import 'package:runearn/feature/goals/data/models/goal_model.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';
import 'package:runearn/feature/goals/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    required this.network,
  });
  final GoalLocalDataSource local;
  final GoalRemoteDataSource remote;
  final FirebaseAuth auth;
  final NetworkInfo network;

  String get _userId {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<FinancialGoal>> getGoals() async {
    await _refresh('goals');
    return (await local.getGoals(_userId))
        .map((item) => GoalModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<List<GoalContribution>> getContributions() async {
    await _refresh('goalContributions');
    return (await local.getContributions(_userId))
        .map((item) => GoalContributionModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  Future<void> _refresh(String collection) async {
    final userId = _userId;
    if (!await network.isConnected) return;
    try {
      await syncPending();
      final pending = (await local.getPending(
        collection,
        userId,
      )).map((item) => item['id']).toSet();
      for (final item in await remote.getAll(collection)) {
        if (pending.contains(item['id'])) continue;
        await local.upsert(collection, {
          ...item,
          'userId': userId,
          'isSynced': 1,
        });
      }
    } catch (_) {}
  }

  @override
  Future<void> saveGoal(FinancialGoal goal) async {
    await _save('goals', GoalModel.fromEntity(goal, _userId).toMap());
  }

  @override
  Future<void> saveContribution(GoalContribution contribution) async {
    await _save(
      'goalContributions',
      GoalContributionModel.fromEntity(contribution, _userId).toMap(),
    );
  }

  Future<void> _save(String table, Map<String, dynamic> data) async {
    await local.upsert(table, {
      ...data,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    });
    await syncPending();
  }

  @override
  Future<void> deleteGoal(String id) async {
    final userId = _userId;
    await local.softDelete('goals', id, userId);
    await local.deleteContributionsForGoal(id, userId);
    await syncPending();
  }

  @override
  Future<void> deleteContribution(String id) async {
    await local.softDelete('goalContributions', id, _userId);
    await syncPending();
  }

  @override
  Future<void> syncPending() async {
    if (!await network.isConnected) return;
    final userId = _userId;
    for (final table in const ['goals', 'goalContributions']) {
      for (final item in await local.getPending(table, userId)) {
        try {
          await remote.upsert(table, {...item, 'isSynced': null});
          await local.markSynced(table, item['id'] as String, userId);
        } catch (_) {}
      }
    }
  }
}
