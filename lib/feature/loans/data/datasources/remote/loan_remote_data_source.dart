import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/sync/firestore_sync_writer.dart';

abstract interface class LoanRemoteDataSource {
  Future<List<Map<String, dynamic>>> getLoans();
  Future<void> upsert(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getPayments();
  Future<void> upsertPayment(Map<String, dynamic> data);
}

class LoanRemoteDataSourceImpl implements LoanRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  const LoanRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('users').doc(_userId).collection('loans');

  CollectionReference<Map<String, dynamic>> get _payments =>
      firestore.collection('users').doc(_userId).collection('loanPayments');

  @override
  Future<List<Map<String, dynamic>>> getLoans() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .toList(growable: false);
  }

  @override
  Future<void> upsert(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: _userId,
      document: _collection.doc(id),
      entityType: 'loans',
      data: data,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPayments() async {
    final snapshot = await _payments.get();
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .toList(growable: false);
  }

  @override
  Future<void> upsertPayment(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: _userId,
      document: _payments.doc(id),
      entityType: 'loanPayments',
      data: data,
    );
  }
}
