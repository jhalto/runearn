import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/core/sync/firestore_sync_writer.dart';

class TransactionRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  TransactionRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance;

  String get userId {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return firestore.collection('users').doc(userId).collection('transactions');
  }

  Future<void> uploadTransaction(Map<String, dynamic> data) async {
    final id = data['id'];

    if (id == null) {
      throw Exception('Transaction id is required');
    }

    await FirestoreSyncWriter.upsert(
      firestore: firestore,
      userId: userId,
      document: _collection.doc(id as String),
      entityType: 'transactions',
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final snapshot = await _collection.get();

    return snapshot.docs.map((doc) {
      return {...doc.data(), 'id': doc.id};
    }).toList();
  }
}
