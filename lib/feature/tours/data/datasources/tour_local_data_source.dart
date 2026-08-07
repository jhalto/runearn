import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class TourLocalDataSource {
  static Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'tours.db'),
    version: 1,
    onConfigure: (db) => db.rawQuery('PRAGMA journal_mode=WAL'),
    onOpen: (db) async {
      await LocalDataCipher.instance.migrateTable(db, 'tours');
      await LocalDataCipher.instance.migrateTable(db, 'tourCollections');
      await LocalDataCipher.instance.migrateTable(db, 'tourExpenses');
    },
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE tours (
          id TEXT NOT NULL, userId TEXT NOT NULL, name TEXT NOT NULL,
          destination TEXT NOT NULL, startDate TEXT NOT NULL,
          endDate TEXT NOT NULL, budget REAL NOT NULL, status TEXT NOT NULL,
          note TEXT NOT NULL, updatedAt TEXT NOT NULL, deletedAt TEXT,
          isSynced INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute('''
        CREATE TABLE tourCollections (
          id TEXT NOT NULL, userId TEXT NOT NULL, tourId TEXT NOT NULL,
          memberName TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL,
          note TEXT NOT NULL, updatedAt TEXT NOT NULL, deletedAt TEXT,
          isSynced INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute('''
        CREATE TABLE tourExpenses (
          id TEXT NOT NULL, userId TEXT NOT NULL, tourId TEXT NOT NULL,
          title TEXT NOT NULL, category TEXT NOT NULL, amount REAL NOT NULL,
          date TEXT NOT NULL, note TEXT NOT NULL, updatedAt TEXT NOT NULL,
          deletedAt TEXT, isSynced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_tours_user ON tours(userId, startDate)',
      );
      await db.execute(
        'CREATE INDEX idx_tour_collections ON tourCollections(userId, tourId)',
      );
      await db.execute(
        'CREATE INDEX idx_tour_expenses ON tourExpenses(userId, tourId)',
      );
    },
  );

  Future<List<Map<String, dynamic>>> getAll(String table, String userId) async {
    final rows = await (await database).query(
      table,
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: table == 'tours' ? 'startDate DESC' : 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows(table, rows);
  }

  Future<List<Map<String, dynamic>>> getPending(
    String table,
    String userId,
  ) async {
    final rows = await (await database).query(
      table,
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows(table, rows);
  }

  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(table, data);
    await (await database).insert(
      table,
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDelete(String table, String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      table,
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> softDeleteForTour(
    String table,
    String tourId,
    String userId,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      table,
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'tourId = ? AND userId = ? AND deletedAt IS NULL',
      whereArgs: [tourId, userId],
    );
  }

  Future<void> markSynced(String table, String id, String userId) async =>
      (await database).update(
        table,
        {'isSynced': 1},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
}
