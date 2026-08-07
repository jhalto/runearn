import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Keeps receipt images inside the app's private documents directory.
///
/// Receipt paths are deliberately local-only and are never sent to Firestore.
class LocalReceiptService {
  LocalReceiptService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int maxBytes = 5 * 1024 * 1024;
  final ImagePicker _picker;

  Future<String?> pickFromGallery(String transactionId) =>
      _pick(ImageSource.gallery, transactionId);

  Future<String?> takePhoto(String transactionId) =>
      _pick(ImageSource.camera, transactionId);

  Future<String?> _pick(ImageSource source, String transactionId) async {
    if (kIsWeb) {
      throw const ReceiptException(
        'Local receipt storage is not available in the web app.',
      );
    }
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (image == null) return null;

    final sourceFile = File(image.path);
    final bytes = await sourceFile.length();
    if (bytes > maxBytes) {
      throw const ReceiptException('Receipt must be smaller than 5 MB.');
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'receipts'));
    await directory.create(recursive: true);
    final extension = p.extension(image.path).toLowerCase();
    final safeExtension = {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
    final destination = p.join(
      directory.path,
      '${transactionId}_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    await sourceFile.copy(destination);
    return destination;
  }

  Future<void> share(String path, {String? description}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ReceiptException('This receipt is no longer on this device.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: description?.trim().isEmpty == false ? description!.trim() : null,
        subject: 'Transaction receipt',
      ),
    );
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class ReceiptException implements Exception {
  const ReceiptException(this.message);
  final String message;

  @override
  String toString() => message;
}
