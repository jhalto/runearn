import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PickedBackupFile {
  const PickedBackupFile({required this.name, required this.content});

  final String name;
  final String content;
}

class BackupFileService {
  const BackupFileService();

  static const int maxImportBytes = 25 * 1024 * 1024;
  static const MethodChannel _storageChannel = MethodChannel(
    'com.jhaltolab.runearn/file_storage',
  );

  Future<PickedBackupFile?> pickBackup() async {
    const typeGroup = XTypeGroup(
      label: 'RunEarn backups',
      extensions: ['runearn', 'json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > maxImportBytes) {
      throw const FormatException('Backup files must be smaller than 25 MB.');
    }
    try {
      return PickedBackupFile(
        name: file.name,
        content: utf8.decode(bytes, allowMalformed: false),
      );
    } on FormatException {
      throw const FormatException('The selected file is not valid text.');
    }
  }

  Future<void> shareExport({required String content, required bool csv}) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final name = csv
        ? 'runearn-transactions-$stamp.csv'
        : 'runearn-backup-$stamp.runearn';
    final mimeType = csv ? 'text/csv' : 'application/json';
    XFile export;
    if (kIsWeb) {
      export = XFile.fromData(
        utf8.encode(content),
        mimeType: mimeType,
        name: name,
      );
    } else {
      final directory = await getTemporaryDirectory();
      final temporaryFile = File(p.join(directory.path, name));
      await temporaryFile.writeAsString(content, flush: true);
      export = XFile(temporaryFile.path, mimeType: mimeType, name: name);
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [export],
        subject: csv ? 'RunEarn transaction export' : 'RunEarn backup',
        text: csv
            ? 'RunEarn transaction CSV export'
            : 'Encrypted RunEarn backup. Keep this file and its password safe.',
      ),
    );
  }

  /// Opens the platform's user-controlled save flow.
  ///
  /// Android uses ACTION_CREATE_DOCUMENT, so users can select Downloads,
  /// Drive, or another document provider without broad storage permissions.
  /// iOS exposes "Save to Files" through its native share sheet.
  Future<bool> saveExport({required String content, required bool csv}) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final name = csv
        ? 'runearn-transactions-$stamp.csv'
        : 'runearn-backup-$stamp.runearn';
    final mimeType = csv ? 'text/csv' : 'application/json';

    if (kIsWeb) {
      await shareExport(content: content, csv: csv);
      return true;
    }

    if (Platform.isAndroid) {
      return await _storageChannel.invokeMethod<bool>('saveExport', {
            'name': name,
            'mimeType': mimeType,
            'content': content,
          }) ??
          false;
    }

    if (Platform.isIOS) {
      await shareExport(content: content, csv: csv);
      return true;
    }

    final location = await getSaveLocation(suggestedName: name);
    if (location == null) return false;
    final file = XFile.fromData(
      utf8.encode(content),
      mimeType: mimeType,
      name: name,
    );
    await file.saveTo(location.path);
    return true;
  }
}
