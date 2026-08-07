import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/data/datasources/remote/profile_remote_data_source.dart';
import 'package:runearn/feature/profile/data/models/user_model.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';
import 'package:runearn/feature/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  @override
  Future<UserEntity> createOrUpdateUserProfile(User user) async {
    final model = await remoteDataSource.createOrUpdateUserProfile(user);
    await _cache(model);
    return model.toEntity();
  }

  @override
  Future<UserEntity?> getCurrentUserProfile() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) return null;

    final cached = await _getCached(uid);
    if (cached != null) return cached.toEntity();

    final model = await remoteDataSource.getCurrentUserProfile();
    if (model != null) await _cache(model);
    return model?.toEntity();
  }

  @override
  Future<void> updateUserProfile(UserEntity user) async {
    final model = UserModel(
      uid: user.uid,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      provider: user.provider,
      isGuest: user.isGuest,
      currency: user.currency,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
    );

    await remoteDataSource.updateUserProfile(model);
    await _cache(model);
  }

  Future<void> _cache(UserModel user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cacheKey(user.uid),
      jsonEncode(user.toCacheMap()),
    );
  }

  Future<UserModel?> _getCached(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_cacheKey(uid));
    if (encoded == null) return null;

    try {
      final data = jsonDecode(encoded);
      if (data is! Map<String, dynamic>) return null;
      final user = UserModel.fromMap(data);
      return user.uid == uid ? user : null;
    } catch (_) {
      await preferences.remove(_cacheKey(uid));
      return null;
    }
  }

  String _cacheKey(String uid) => 'cached_user_profile_$uid';
}
