import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class BackupCipher {
  BackupCipher({Cipher? cipher, KdfAlgorithm? keyDerivation})
    : _cipher = cipher ?? AesGcm.with256bits(),
      _keyDerivation =
          keyDerivation ??
          Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: iterations,
            bits: 256,
          );

  static const format = 'runearn-encrypted-backup';
  static const envelopeVersion = 1;
  static const iterations = 210000;

  final Cipher _cipher;
  final KdfAlgorithm _keyDerivation;

  Future<String> encrypt(String clearText, String password) async {
    _validatePassword(password);
    final salt = _randomBytes(16);
    final key = await _keyDerivation.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = await _cipher.encrypt(utf8.encode(clearText), secretKey: key);
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'RunEarn',
      'format': format,
      'version': envelopeVersion,
      'kdf': {
        'name': 'PBKDF2-HMAC-SHA256',
        'iterations': iterations,
        'salt': base64UrlEncode(salt),
      },
      'cipher': {
        'name': 'AES-256-GCM',
        'nonce': base64UrlEncode(box.nonce),
        'cipherText': base64UrlEncode(box.cipherText),
        'mac': base64UrlEncode(box.mac.bytes),
      },
    });
  }

  Future<String> decrypt(String source, String password) async {
    final root = _decodeMap(source);
    // Version 1 backups were plaintext. They remain importable so existing
    // users are not locked out of their data, but all new exports are encrypted.
    if (root['format'] != format) return source;
    if (root['version'] != envelopeVersion) {
      throw FormatException(
        'Unsupported encrypted backup version: ${root['version']}.',
      );
    }
    if (password.isEmpty) {
      throw const FormatException('Enter the backup password.');
    }

    final kdf = _map(root['kdf'], 'kdf');
    final cipher = _map(root['cipher'], 'cipher');
    if (kdf['name'] != 'PBKDF2-HMAC-SHA256' ||
        kdf['iterations'] != iterations ||
        cipher['name'] != 'AES-256-GCM') {
      throw const FormatException('Unsupported backup encryption settings.');
    }
    try {
      final salt = base64Url.decode(_string(kdf, 'salt'));
      final key = await _keyDerivation.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      final bytes = await _cipher.decrypt(
        SecretBox(
          base64Url.decode(_string(cipher, 'cipherText')),
          nonce: base64Url.decode(_string(cipher, 'nonce')),
          mac: Mac(base64Url.decode(_string(cipher, 'mac'))),
        ),
        secretKey: key,
      );
      return utf8.decode(bytes);
    } on SecretBoxAuthenticationError {
      throw const FormatException(
        'Incorrect password or the backup has been modified.',
      );
    } on FormatException catch (error) {
      if (error.message ==
          'Incorrect password or the backup has been modified.') {
        rethrow;
      }
      throw const FormatException('The encrypted backup is damaged.');
    }
  }

  Map<String, dynamic> _decodeMap(String source) {
    try {
      return _map(jsonDecode(source), 'backup');
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('The backup is not valid JSON.');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 10) {
      throw const FormatException(
        'Use a backup password with at least 10 characters.',
      );
    }
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

Map<String, dynamic> _map(Object? value, String name) {
  if (value is! Map) throw FormatException('$name must be an object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _string(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! String || value.isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}
