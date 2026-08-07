class UserEntity {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final String provider;
  final bool isGuest;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.provider,
    required this.isGuest,
    required this.currency,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  UserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? provider,
    bool? isGuest,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      isGuest: isGuest ?? this.isGuest,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}