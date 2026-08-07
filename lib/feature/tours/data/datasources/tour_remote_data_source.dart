import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/sync/firestore_sync_writer.dart';

class TourRemoteDataSource {
  const TourRemoteDataSource(this.firestore, this.auth);
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = auth.currentUser;
    if (user == null) throw StateError('User is not authenticated');
    return firestore.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>> get _tours =>
      _userDocument.collection('tours');

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    if (collection == 'tours') {
      final snapshot = await _tours.get();
      return snapshot.docs
          .map((document) => {...document.data(), 'id': document.id})
          .toList(growable: false);
    }

    final nestedName = _nestedCollectionName(collection);
    final records = <String, Map<String, dynamic>>{};
    final tours = await _tours.get();
    for (final tour in tours.docs) {
      final snapshot = await tour.reference.collection(nestedName).get();
      for (final document in snapshot.docs) {
        records['${tour.id}/${document.id}'] = {
          ...document.data(),
          'id': document.id,
          'tourId': tour.id,
        };
      }
    }

    // One-time migration for records written by the original flat schema.
    final legacy = await _userDocument.collection(collection).get();
    for (final document in legacy.docs) {
      final data = document.data();
      final tourId = data['tourId'];
      if (tourId is! String || tourId.isEmpty) continue;
      records['$tourId/${document.id}'] = {
        ...data,
        'id': document.id,
        'tourId': tourId,
      };
    }
    return records.values.toList(growable: false);
  }

  Future<void> upsert(String collection, Map<String, dynamic> data) async {
    final remote = Map<String, dynamic>.of(data)
      ..remove('userId')
      ..remove('isSynced');
    final id = data['id'] as String;
    if (collection == 'tours') {
      await FirestoreSyncWriter.upsert(
        firestore: firestore,
        userId: auth.currentUser!.uid,
        document: _tours.doc(id),
        entityType: 'tours',
        data: remote,
      );
      return;
    }

    final tourId = data['tourId'];
    if (tourId is! String || tourId.isEmpty) {
      throw StateError('$collection record is missing its tourId');
    }
    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: auth.currentUser!.uid,
      document: _tours
          .doc(tourId)
          .collection(_nestedCollectionName(collection))
          .doc(id),
      entityType: collection,
      data: remote,
    );
  }

  String _nestedCollectionName(String collection) => switch (collection) {
    'tourCollections' => 'collections',
    'tourExpenses' => 'expenses',
    _ => throw ArgumentError.value(
      collection,
      'collection',
      'Unsupported tour collection',
    ),
  };
}
