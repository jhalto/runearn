import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/loans/data/datasources/local/loan_local_data_source.dart';
import 'package:runearn/feature/loans/data/datasources/remote/loan_remote_data_source.dart';
import 'package:runearn/feature/loans/data/models/loan_model.dart';
import 'package:runearn/feature/loans/data/models/loan_payment_model.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanLocalDataSource localDataSource;
  final LoanRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;
  final NetworkInfo networkInfo;

  const LoanRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.firebaseAuth,
    required this.networkInfo,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  @override
  Future<List<Loan>> getLoans() async {
    final userId = _userId;
    if (await networkInfo.isConnected) {
      try {
        await syncPendingLoans();
        final remoteLoans = await remoteDataSource.getLoans();
        final pending = await localDataSource.getPendingLoans(userId);
        final pendingIds = pending.map((item) => item['id']).toSet();
        for (final remote in remoteLoans) {
          if (pendingIds.contains(remote['id'])) continue;
          await localDataSource.upsert({
            ...remote,
            'userId': userId,
            'isSettled': remote['isSettled'] == true ? 1 : 0,
            'isSynced': 1,
          });
        }
      } catch (_) {
        // Local data remains available when the remote service is unavailable.
      }
    }

    final localLoans = await localDataSource.getLoans(userId);
    return localLoans
        .map((item) => LoanModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> addLoan(Loan loan) => _save(loan);

  @override
  Future<void> updateLoan(Loan loan) => _save(loan);

  Future<void> _save(Loan loan) async {
    final userId = _userId;
    final model = LoanModel.fromEntity(loan, userId: userId);
    final data = {
      ...model.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    };
    await localDataSource.upsert(data);
    await _tryRemoteSync(data, model);
  }

  @override
  Future<void> deleteLoan(String id) async {
    final userId = _userId;
    await localDataSource.softDelete(id, userId);
    await localDataSource.deletePaymentsForLoan(id, userId);
    if (await networkInfo.isConnected) {
      await syncPendingLoans();
    }
  }

  Future<void> _tryRemoteSync(
    Map<String, dynamic> localData,
    LoanModel model,
  ) async {
    if (!await networkInfo.isConnected) return;
    try {
      await remoteDataSource.upsert({
        ...model.toRemoteMap(),
        'updatedAt': localData['updatedAt'],
        'deletedAt': localData['deletedAt'],
      });
      await localDataSource.markAsSynced(model.id, model.userId);
    } catch (_) {
      // The row remains pending and will be retried later.
    }
  }

  @override
  Future<void> syncPendingLoans() async {
    if (!await networkInfo.isConnected) return;
    final userId = _userId;
    final pending = await localDataSource.getPendingLoans(userId);
    for (final item in pending) {
      try {
        final model = LoanModel.fromMap(item);
        await remoteDataSource.upsert({
          ...model.toRemoteMap(),
          'updatedAt': item['updatedAt'],
          'deletedAt': item['deletedAt'],
        });
        await localDataSource.markAsSynced(model.id, userId);
      } catch (_) {
        // Continue syncing independent records.
      }
    }
    for (final item in await localDataSource.getPendingPayments(userId)) {
      try {
        await remoteDataSource.upsertPayment({...item, 'isSynced': null});
        await localDataSource.markPaymentSynced(item['id'] as String, userId);
      } catch (_) {}
    }
  }

  @override
  Future<void> clearLoans() async {
    final userId = _userId;
    await localDataSource.softDeleteAll(userId);
    if (await networkInfo.isConnected) {
      await syncPendingLoans();
    }
  }

  @override
  Future<List<LoanPayment>> getPayments() async {
    final userId = _userId;
    if (await networkInfo.isConnected) {
      try {
        await syncPendingLoans();
        final pendingIds = (await localDataSource.getPendingPayments(
          userId,
        )).map((item) => item['id']).toSet();
        for (final item in await remoteDataSource.getPayments()) {
          if (pendingIds.contains(item['id'])) continue;
          await localDataSource.upsertPayment({
            ...item,
            'userId': userId,
            'isSynced': 1,
          });
        }
      } catch (_) {}
    }
    return (await localDataSource.getPayments(userId))
        .map((item) => LoanPaymentModel.fromMap(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> savePayment(LoanPayment payment) async {
    final userId = _userId;
    final model = LoanPaymentModel.fromEntity(payment, userId: userId);
    await localDataSource.upsertPayment({
      ...model.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deletedAt': null,
      'isSynced': 0,
    });
    await syncPendingLoans();
  }

  @override
  Future<void> deletePayment(String id) async {
    await localDataSource.deletePayment(id, _userId);
    await syncPendingLoans();
  }
}
