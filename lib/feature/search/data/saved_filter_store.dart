import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/saved_transaction_filter.dart';

class SavedFilterStore {
  SavedFilterStore({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String get _key =>
      'transaction.saved_filters.${_auth.currentUser?.uid ?? 'guest'}';

  Future<List<SavedTransactionFilter>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map(
            (item) => SavedTransactionFilter.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<SavedTransactionFilter> filters) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(filters.map((item) => item.toMap()).toList()),
    );
  }
}
