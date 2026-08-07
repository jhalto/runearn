import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class RecurringLocalDataSource {
  static Future<Database>? _database;
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'recurring.db'),
    version: 1,
    onConfigure: (db) => db.rawQuery('PRAGMA journal_mode=WAL'),
    onOpen: (db) =>
        LocalDataCipher.instance.migrateTable(db, 'recurringTransactions'),
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE recurringTransactions (
          id TEXT NOT NULL, userId TEXT NOT NULL, title TEXT NOT NULL,
          amount REAL NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL,
          customCategory TEXT, accountId TEXT, frequency TEXT NOT NULL,
          nextDue TEXT NOT NULL, note TEXT NOT NULL DEFAULT '',
          isActive INTEGER NOT NULL DEFAULT 1, updatedAt TEXT NOT NULL,
          deletedAt TEXT, isSynced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_recurring_due '
        'ON recurringTransactions(userId, nextDue)',
      );
    },
  );

  Future<List<Map<String, dynamic>>> getAll(String userId) async {
    final rows = await (await database).query(
      'recurringTransactions',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'isActive DESC, nextDue ASC',
    );
    return LocalDataCipher.instance.unprotectRows(
      'recurringTransactions',
      rows,
    );
  }

  Future<List<Map<String, dynamic>>> getPending(String userId) async {
    final rows = await (await database).query(
      'recurringTransactions',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows(
      'recurringTransactions',
      rows,
    );
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(
      'recurringTransactions',
      data,
    );
    await (await database).insert(
      'recurringTransactions',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDelete(String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'recurringTransactions',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> markSynced(String id, String userId) async =>
      (await database).update(
        'recurringTransactions',
        {'isSynced': 1},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
}
