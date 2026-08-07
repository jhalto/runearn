import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/core/sync/sync_conflict_resolver.dart';

void main() {
  test('newer local change wins over an older remote record', () {
    expect(
      SyncConflictResolver.shouldApply(
        localUpdatedAt: '2026-07-29T10:00:00Z',
        remoteUpdatedAt: '2026-07-29T09:59:59Z',
      ),
      isTrue,
    );
  });

  test('older and equal retries never overwrite remote state', () {
    expect(
      SyncConflictResolver.shouldApply(
        localUpdatedAt: '2026-07-29T10:00:00Z',
        remoteUpdatedAt: '2026-07-29T10:00:00Z',
      ),
      isFalse,
    );
    expect(
      SyncConflictResolver.shouldApply(
        localUpdatedAt: '2026-07-29T09:00:00Z',
        remoteUpdatedAt: '2026-07-29T10:00:00Z',
      ),
      isFalse,
    );
  });

  test('audit event identifier is deterministic for idempotent retries', () {
    final first = SyncConflictResolver.auditId(
      'transactions',
      'record-1',
      '2026-07-29T10:00:00.000Z',
    );
    final second = SyncConflictResolver.auditId(
      'transactions',
      'record-1',
      '2026-07-29T10:00:00.000Z',
    );

    expect(first, second);
    expect(first, isNot(contains('/')));
  });
}
