import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

/// Encrypts sensitive SQLite fields while leaving identifiers and sync
/// metadata queryable. AES-GCM provides both confidentiality and tamper
/// detection. The random database key is held by the platform secure store.
class LocalDataCipher {
  LocalDataCipher._();

  static final LocalDataCipher instance = LocalDataCipher._();

  static const _keyName = 'runearn.local_database_key.v1';
  static const _prefix = 'rue1:';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      migrateWithBackup: true,
      storageNamespace: 'runearn_finance',
    ),
  );

  final Cipher _algorithm = AesGcm.with256bits();
  SecretKey? _secretKey;

  static const Map<String, Set<String>> _sensitiveFields = {
    'transactions': {
      'amount',
      'customCategory',
      'description',
      'localReceiptPath',
      'tags',
      'splits',
    },
    'accounts': {
      'name',
      'balance',
      'note',
      'creditLimit',
      'minimumPaymentAmount',
    },
    'accountTransfers': {'amount', 'receivedAmount', 'note'},
    'loans': {'personName', 'amount', 'note', 'annualInterestRate'},
    'loanPayments': {'amount', 'note'},
    'budgets': {'categoryName', 'limit', 'templateName'},
    'goals': {'name', 'targetAmount', 'note'},
    'goalContributions': {'amount', 'note'},
    'recurringTransactions': {'title', 'amount', 'customCategory', 'note'},
    'tours': {'name', 'destination', 'budget', 'note'},
    'tourCollections': {'memberName', 'amount', 'note'},
    'tourExpenses': {'title', 'category', 'amount', 'note'},
  };

  Future<void> initialize() async {
    if (_secretKey != null) return;
    final encoded = await _storage.read(key: _keyName);
    if (encoded != null) {
      final bytes = base64Url.decode(encoded);
      if (bytes.length != 32) {
        throw const LocalEncryptionException(
          'The local encryption key is invalid. Local data was not opened.',
        );
      }
      _secretKey = SecretKey(bytes);
      return;
    }

    final key = await _algorithm.newSecretKey();
    final bytes = await key.extractBytes();
    await _storage.write(key: _keyName, value: base64Url.encode(bytes));
    _secretKey = key;
  }

  /// Removes the device-held database key after an account purge.
  Future<void> deleteKey() async {
    _secretKey = null;
    await _storage.delete(key: _keyName);
  }

  Future<Map<String, dynamic>> protectMap(
    String table,
    Map<String, dynamic> source,
  ) async {
    await initialize();
    final fields = _sensitiveFields[table];
    if (fields == null) return Map<String, dynamic>.from(source);
    final output = Map<String, dynamic>.from(source);
    for (final field in fields) {
      final value = output[field];
      if (value == null || _isEncrypted(value)) continue;
      output[field] = await _encrypt(value, '$table:$field');
    }
    return output;
  }

  Future<Map<String, dynamic>> unprotectMap(
    String table,
    Map<String, dynamic> source,
  ) async {
    await initialize();
    final fields = _sensitiveFields[table];
    if (fields == null) return Map<String, dynamic>.from(source);
    final output = Map<String, dynamic>.from(source);
    for (final field in fields) {
      final value = output[field];
      if (!_isEncrypted(value)) continue;
      output[field] = await _decrypt(value as String, '$table:$field');
    }
    return output;
  }

  Future<List<Map<String, dynamic>>> unprotectRows(
    String table,
    List<Map<String, dynamic>> rows,
  ) async => Future.wait(rows.map((row) => unprotectMap(table, row)));

  /// Idempotently encrypts records created by older app versions.
  Future<void> migrateTable(Database db, String table) async {
    final fields = _sensitiveFields[table];
    if (fields == null) return;
    final rows = await db.query(table);
    await db.transaction((transaction) async {
      for (final row in rows) {
        final needsMigration = fields.any((field) {
          final value = row[field];
          return value != null && !_isEncrypted(value);
        });
        if (!needsMigration) continue;
        final protected = await protectMap(table, row);
        await transaction.update(
          table,
          protected,
          where: 'id = ? AND userId = ?',
          whereArgs: [row['id'], row['userId']],
        );
      }
    });
  }

  Future<String> _encrypt(Object value, String context) async {
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: _requiredKey,
      nonce: nonce,
      aad: utf8.encode(context),
    );
    final payload = <String, Object>{
      'n': base64UrlEncode(box.nonce),
      'c': base64UrlEncode(box.cipherText),
      'm': base64UrlEncode(box.mac.bytes),
    };
    return '$_prefix${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';
  }

  Future<Object?> _decrypt(String value, String context) async {
    try {
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(value.substring(_prefix.length))),
              )
              as Map<String, dynamic>;
      final clearBytes = await _algorithm.decrypt(
        SecretBox(
          base64Url.decode(payload['c'] as String),
          nonce: base64Url.decode(payload['n'] as String),
          mac: Mac(base64Url.decode(payload['m'] as String)),
        ),
        secretKey: _requiredKey,
        aad: utf8.encode(context),
      );
      return jsonDecode(utf8.decode(clearBytes));
    } on SecretBoxAuthenticationError {
      throw const LocalEncryptionException(
        'Encrypted local data failed its integrity check.',
      );
    } on FormatException {
      throw const LocalEncryptionException(
        'Encrypted local data has an invalid format.',
      );
    }
  }

  SecretKey get _requiredKey {
    final key = _secretKey;
    if (key == null) {
      throw const LocalEncryptionException(
        'The local encryption key is unavailable.',
      );
    }
    return key;
  }

  bool _isEncrypted(Object? value) =>
      value is String && value.startsWith(_prefix);
}

class LocalEncryptionException implements Exception {
  const LocalEncryptionException(this.message);
  final String message;

  @override
  String toString() => message;
}
