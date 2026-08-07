import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> createOrUpdateUserProfile(User user);

  Future<UserModel?> getCurrentUserProfile();

  Future<void> updateUserProfile(UserModel user);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return firestore.collection('users');
  }

  @override
  Future<UserModel> createOrUpdateUserProfile(User user) async {
    final userRef = _usersCollection.doc(user.uid);
    final snapshot = await userRef.get();

    final model = UserModel.fromFirebaseUser(user);
    final data = model.toMap(includeCreatedAt: !snapshot.exists);

    // A profile name belongs to the user. Do not replace an existing edited
    // name with Firebase's display name/email fallback on every login.
    if (snapshot.exists) {
      data.remove('name');
      data.remove('currency');
    }

    await userRef.set(data, SetOptions(merge: true));

    final updatedSnapshot = await userRef.get();

    return UserModel.fromMap(updatedSnapshot.data()!);
  }

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    final user = firebaseAuth.currentUser;

    if (user == null) return null;

    final snapshot = await _usersCollection.doc(user.uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return createOrUpdateUserProfile(user);
    }

    return UserModel.fromMap(snapshot.data()!);
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).set({
      'name': user.name,
      'photoUrl': user.photoUrl,
      'currency': user.currency,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
