import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/tours/data/datasources/tour_local_data_source.dart';
import 'package:runearn/feature/tours/data/datasources/tour_remote_data_source.dart';
import 'package:runearn/feature/tours/data/models/tour_models.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';
import 'package:runearn/feature/tours/domain/repositories/tour_repository.dart';

class TourRepositoryImpl implements TourRepository {
  const TourRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    required this.network,
  });

  final TourLocalDataSource local;
  final TourRemoteDataSource remote;
  final FirebaseAuth auth;
  final NetworkInfo network;

  static const _tables = ['tours', 'tourCollections', 'tourExpenses'];

  String get _userId {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<Tour>> getTours() async {
    await _refresh();
    return (await local.getAll(
      'tours',
      _userId,
    )).map(tourFromMap).toList(growable: false);
  }

  @override
  Future<List<TourCollection>> getCollections() async => (await local.getAll(
    'tourCollections',
    _userId,
  )).map(collectionFromMap).toList(growable: false);

  @override
  Future<List<TourExpense>> getExpenses() async => (await local.getAll(
    'tourExpenses',
    _userId,
  )).map(expenseFromMap).toList(growable: false);

  @override
  Future<void> saveTour(Tour tour) => _save('tours', tourToMap(tour, _userId));

  @override
  Future<void> saveCollection(TourCollection item) =>
      _save('tourCollections', collectionToMap(item, _userId));

  @override
  Future<void> saveExpense(TourExpense item) =>
      _save('tourExpenses', expenseToMap(item, _userId));

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
  Future<void> deleteTour(String id) async {
    final userId = _userId;
    await local.softDelete('tours', id, userId);
    await local.softDeleteForTour('tourCollections', id, userId);
    await local.softDeleteForTour('tourExpenses', id, userId);
    await syncPending();
  }

  @override
  Future<void> deleteCollection(String id) => _delete('tourCollections', id);

  @override
  Future<void> deleteExpense(String id) => _delete('tourExpenses', id);

  Future<void> _delete(String table, String id) async {
    await local.softDelete(table, id, _userId);
    await syncPending();
  }

  Future<void> _refresh() async {
    if (!await network.isConnected) return;
    final userId = _userId;
    try {
      await syncPending();
      for (final table in _tables) {
        final pending = (await local.getPending(
          table,
          userId,
        )).map((item) => item['id']).toSet();
        for (final item in await remote.getAll(table)) {
          if (pending.contains(item['id'])) continue;
          await local.upsert(table, {...item, 'userId': userId, 'isSynced': 1});
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> syncPending() async {
    if (!await network.isConnected) return;
    final userId = _userId;
    Object? firstFailure;
    for (final table in _tables) {
      for (final item in await local.getPending(table, userId)) {
        try {
          await remote.upsert(table, item);
          await local.markSynced(table, item['id'] as String, userId);
        } catch (error) {
          // Keep the local row pending so background sync can retry it.
          firstFailure ??= error;
        }
      }
    }
    if (firstFailure != null) {
      throw StateError(
        'Tour data was saved offline but Firestore sync failed: '
        '$firstFailure',
      );
    }
  }
}
