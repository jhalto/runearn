import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:runearn/feature/transactions/domain/services/local_receipt_service.dart';

class LocalReceiptField extends StatelessWidget {
  const LocalReceiptField({
    required this.transactionId,
    required this.path,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String transactionId;
  final String? path;
  final ValueChanged<String?> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final service = LocalReceiptService();
    final hasReceipt = path?.isNotEmpty == true && !kIsWeb;

    Future<void> pick(bool camera) async {
      try {
        final selected = camera
            ? await service.takePhoto(transactionId)
            : await service.pickFromGallery(transactionId);
        if (selected == null) return;
        onChanged(selected);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }

    if (hasReceipt) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path!),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.square(
                  dimension: 58,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt attached',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text('Saved only on this device'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Share receipt',
              onPressed: () async {
                try {
                  await service.share(path!, description: description);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'Remove receipt',
              onPressed: () async {
                onChanged(null);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: kIsWeb
          ? null
          : () async {
              final source = await showModalBottomSheet<bool>(
                context: context,
                showDragHandle: true,
                builder: (sheetContext) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt_outlined),
                        title: const Text('Take a photo'),
                        onTap: () => Navigator.pop(sheetContext, true),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Choose from gallery'),
                        onTap: () => Navigator.pop(sheetContext, false),
                      ),
                    ],
                  ),
                ),
              );
              if (source != null) await pick(source);
            },
      icon: const Icon(Icons.receipt_long_outlined),
      label: Text(kIsWeb ? 'Receipts unavailable on web' : 'Attach receipt'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
