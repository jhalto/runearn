class SyncConflictResolver {
  const SyncConflictResolver._();

  static bool shouldApply({
    required Object? localUpdatedAt,
    required Object? remoteUpdatedAt,
  }) {
    final local = parseDate(localUpdatedAt);
    if (local == null) return false;
    final remote = parseDate(remoteUpdatedAt);
    return remote == null || local.isAfter(remote);
  }

  static DateTime? parseDate(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  static String auditId(String type, String id, String updatedAt) {
    final source = '$type|$id|$updatedAt';
    var hash = 0x811c9dc5;
    for (final unit in source.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return '${type}_${id}_$hash';
  }
}
