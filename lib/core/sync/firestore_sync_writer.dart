import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runearn/core/observability/app_observability.dart';
import 'package:runearn/core/sync/sync_conflict_resolver.dart';

class FirestoreSyncWriter {
  const FirestoreSyncWriter._();

  static Future<bool> upsert({
    required FirebaseFirestore firestore,
    required String userId,
    required DocumentReference<Map<String, dynamic>> document,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    final incoming = Map<String, dynamic>.of(data)
      ..remove('isSynced')
      ..removeWhere((key, value) => value == null && key == 'isSynced');
    final incomingUpdatedAt = _date(incoming['updatedAt']);
    if (incomingUpdatedAt == null) {
      throw StateError('$entityType record is missing updatedAt');
    }

    return AppObservability.instance.trace('firestore_sync_write', () {
      return firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(document);
      final current = currentSnapshot.data();
      final currentUpdatedAt = _date(current?['updatedAt']);
      if (!SyncConflictResolver.shouldApply(
        localUpdatedAt: incomingUpdatedAt,
        remoteUpdatedAt: currentUpdatedAt,
      )) {
        return false;
      }

      final action = incoming['deletedAt'] != null
          ? 'delete'
          : currentSnapshot.exists
          ? 'update'
          : 'create';
      transaction.set(document, incoming, SetOptions(merge: true));
      final auditId = SyncConflictResolver.auditId(
        entityType,
        document.id,
        incomingUpdatedAt.toUtc().toIso8601String(),
      );
      final audit = firestore
          .collection('users')
          .doc(userId)
          .collection('auditLogs')
          .doc(auditId);
      transaction.set(audit, {
        'entityType': entityType,
        'entityId': document.id,
        'action': action,
        'clientUpdatedAt': incomingUpdatedAt.toUtc().toIso8601String(),
        'recordedAt': FieldValue.serverTimestamp(),
        'changedFields':
            incoming.keys
                .where(
                  (key) =>
                      key != 'userId' &&
                      key != 'updatedAt' &&
                      key != 'deletedAt',
                )
                .toList(growable: false)
              ..sort(),
      });
      return true;
      });
    }, attributes: {'entity_type': entityType});
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
