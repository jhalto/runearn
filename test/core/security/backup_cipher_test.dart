import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/core/security/backup_cipher.dart';

void main() {
  late BackupCipher cipher;

  setUp(() {
    cipher = BackupCipher(
      keyDerivation: Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 2,
        bits: 256,
      ),
    );
  });

  test('encrypted backup round trips with the correct password', () async {
    const source = '{"app":"RunEarn","version":1,"data":{"accounts":[]}}';

    final encrypted = await cipher.encrypt(source, 'correct horse battery');
    final decrypted = await cipher.decrypt(encrypted, 'correct horse battery');

    expect(decrypted, source);
    expect(encrypted, isNot(contains('"accounts"')));
    expect(jsonDecode(encrypted)['format'], BackupCipher.format);
  });

  test('wrong password is rejected', () async {
    final encrypted = await cipher.encrypt(
      '{"private":"financial data"}',
      'correct horse battery',
    );

    expect(
      () => cipher.decrypt(encrypted, 'incorrect password!'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Incorrect password'),
        ),
      ),
    );
  });

  test('modified ciphertext is rejected', () async {
    final encrypted = await cipher.encrypt(
      '{"private":"financial data"}',
      'correct horse battery',
    );
    final envelope = jsonDecode(encrypted) as Map<String, dynamic>;
    final encryptedData = envelope['cipher'] as Map<String, dynamic>;
    final text = encryptedData['cipherText'] as String;
    encryptedData['cipherText'] = '${text.substring(0, text.length - 2)}AA';

    expect(
      () => cipher.decrypt(jsonEncode(envelope), 'correct horse battery'),
      throwsA(isA<FormatException>()),
    );
  });

  test('legacy plaintext backup remains importable', () async {
    const source = '{"app":"RunEarn","version":1,"data":{}}';

    expect(await cipher.decrypt(source, ''), source);
  });

  test('short backup password is rejected', () async {
    expect(
      () => cipher.encrypt('{}', 'short'),
      throwsA(isA<FormatException>()),
    );
  });
}
