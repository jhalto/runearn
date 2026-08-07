import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';

import 'package:runearn/feature/transactions/data/datasources/local/transaction_db.dart';
import 'package:runearn/feature/transactions/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:runearn/feature/transactions/data/models/transaction_model.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';
import 'package:runearn/feature/transactions/domain/services/local_receipt_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;
  final NetworkInfo networkInfo;
  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
    required this.networkInfo,
  });
  Future<bool> get _hasInternet => networkInfo.isConnected;

  Map<String, dynamic> _remoteData(Map<String, dynamic> data) =>
      Map<String, dynamic>.from(data)..remove('localReceiptPath');

  String get _userId {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return user.uid;
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final userId = _userId;
    final hasInternet = await _hasInternet;

    if (hasInternet) {
      try {
        await syncPendingTransactions();

        final remoteData = await remoteDataSource.fetchTransactions();
        final pending = await TransactionDB.getUnsyncedTransactions(userId);
        final pendingIds = pending.map((item) => item['id']).toSet();

        for (final item in remoteData) {
          if (pendingIds.contains(item['id'])) continue;
          await TransactionDB.upsertFromRemote({...item, 'userId': userId});
        }
      } catch (e) {
        // If Firebase fails, app still shows local data.
      }
    }

    final data = await TransactionDB.getTransactions(userId);

    return data.map((e) {
      return TransactionModel.fromMap(e).toEntity();
    }).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    _validateSplits(transaction);
    final userId = _userId;

    final model = TransactionModel.fromEntity(transaction, userId: userId);

    final data = {
      ...model.toMap(),
      'userId': userId,
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'deletedAt': null,
    };

    await TransactionDB.insertTransaction(data);

    if (await _hasInternet) {
      try {
        await remoteDataSource.uploadTransaction(_remoteData(data));
        await TransactionDB.markAsSynced(data['id'], userId);
      } catch (e) {
        // Keep as unsynced
      }
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    _validateSplits(transaction);
    final userId = _userId;

    final model = TransactionModel.fromEntity(transaction, userId: userId);

    final data = {
      ...model.toMap(),
      'userId': userId,
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await TransactionDB.updateTransaction(data, userId);

    if (await _hasInternet) {
      try {
        await remoteDataSource.uploadTransaction(_remoteData(data));
        await TransactionDB.markAsSynced(data['id'], userId);
      } catch (e) {
        // Keep as unsynced
      }
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final userId = _userId;
    final localItems = await TransactionDB.getTransactions(userId);
    String? receiptPath;
    for (final item in localItems) {
      if (item['id'] == id) {
        receiptPath = item['localReceiptPath'] as String?;
        break;
      }
    }

    await TransactionDB.deleteTransaction(id, userId);
    await LocalReceiptService().delete(receiptPath);

    if (await _hasInternet) {
      try {
        await remoteDataSource.uploadTransaction({
          'id': id,
          'userId': userId,
          'deletedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        await TransactionDB.markAsSynced(id, userId);
      } catch (e) {
        // Keep as unsynced
      }
    }
  }

  @override
  Future<void> syncPendingTransactions() async {
    if (!await _hasInternet) return;

    final userId = _userId;

    final unsyncedItems = await TransactionDB.getUnsyncedTransactions(userId);

    for (final item in unsyncedItems) {
      try {
        await remoteDataSource.uploadTransaction(
          _remoteData({...item, 'userId': userId}),
        );

        await TransactionDB.markAsSynced(item['id'], userId);
      } catch (e) {
        // Continue next item
      }
    }
  }

  @override
  Future<void> clearTransactions({TransactionType? type}) async {
    final userId = _userId;
    final localItems = await TransactionDB.getTransactions(userId);
    for (final item in localItems) {
      if (type == null || item['type'] == type.name) {
        await LocalReceiptService().delete(item['localReceiptPath'] as String?);
      }
    }
    await TransactionDB.clearUserTransactions(userId, type: type?.name);
    if (await _hasInternet) {
      await syncPendingTransactions();
    }
  }

  void _validateSplits(Transaction transaction) {
    if (transaction.splits.isEmpty) return;
    if (transaction.splits.length < 2) {
      throw const FormatException(
        'A split transaction requires at least two categories.',
      );
    }
    if (transaction.splits.any((item) => item.amount <= 0)) {
      throw const FormatException('Every split amount must be greater than 0.');
    }
    final splitTotal = transaction.splits.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    if ((splitTotal - transaction.amount).abs() > 0.01) {
      throw FormatException(
        'Split amounts must equal ${transaction.amount.toStringAsFixed(2)}.',
      );
    }
  }
}
