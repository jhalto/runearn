import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.photoUrl,
    required super.provider,
    required super.isGuest,
    required super.currency,
    super.createdAt,
    super.updatedAt,
    super.lastLoginAt,
  });

  factory UserModel.fromFirebaseUser(User user) {
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : user.isAnonymous
        ? 'anonymous'
        : 'password';

    return UserModel(
      uid: user.uid,
      name: user.isAnonymous
          ? 'Guest'
          : user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : user.email?.split('@').first ?? 'User',
      email: user.email,
      photoUrl: user.photoURL,
      provider: provider,
      isGuest: user.isAnonymous,
      currency: 'BDT',
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'User',
      email: map['email'],
      photoUrl: map['photoUrl'],
      provider: map['provider'] ?? 'unknown',
      isGuest: map['isGuest'] ?? false,
      currency: map['currency'] ?? 'BDT',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      lastLoginAt: _parseDate(map['lastLoginAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    final data = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'isGuest': isGuest,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    return data;
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'isGuest': isGuest,
      'currency': currency,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
      provider: provider,
      isGuest: isGuest,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
