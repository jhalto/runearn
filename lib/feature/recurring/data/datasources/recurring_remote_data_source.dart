import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/sync/firestore_sync_writer.dart';

class RecurringRemoteDataSource {
  const RecurringRemoteDataSource(this.firestore, this.auth);
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('recurringTransactions');
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .toList(growable: false);
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: auth.currentUser!.uid,
      document: _collection.doc(id),
      entityType: 'recurringTransactions',
      data: data,
    );
  }
}
