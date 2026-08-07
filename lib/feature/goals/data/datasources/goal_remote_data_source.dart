import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/sync/firestore_sync_writer.dart';

class GoalRemoteDataSource {
  const GoalRemoteDataSource(this.firestore, this.auth);
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> _collection(String name) {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return firestore.collection('users').doc(user.uid).collection(name);
  }

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final snapshot = await _collection(collection).get();
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .toList(growable: false);
  }

  Future<void> upsert(String collection, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: auth.currentUser!.uid,
      document: _collection(collection).doc(id),
      entityType: collection,
      data: data,
    );
  }
}
