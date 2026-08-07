import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class GoalLocalDataSource {
  static Future<Database>? _database;
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'goals.db'),
    version: 2,
    onConfigure: (db) => db.rawQuery('PRAGMA journal_mode=WAL'),
    onOpen: (db) async {
      await _ensureContributionAccountColumns(db);
      await LocalDataCipher.instance.migrateTable(db, 'goals');
      await LocalDataCipher.instance.migrateTable(db, 'goalContributions');
    },
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE goals (
          id TEXT NOT NULL, userId TEXT NOT NULL, name TEXT NOT NULL,
          targetAmount REAL NOT NULL, createdAt TEXT NOT NULL,
          deadline TEXT, note TEXT NOT NULL DEFAULT '',
          updatedAt TEXT NOT NULL, deletedAt TEXT,
          isSynced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute('''
        CREATE TABLE goalContributions (
          id TEXT NOT NULL, userId TEXT NOT NULL, goalId TEXT NOT NULL,
          amount REAL NOT NULL, date TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '', updatedAt TEXT NOT NULL,
          sourceAccountId TEXT, goalAccountId TEXT, transferId TEXT,
          deletedAt TEXT, isSynced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_goals_user ON goals(userId, createdAt)',
      );
      await db.execute(
        'CREATE INDEX idx_goal_contributions '
        'ON goalContributions(userId, goalId, date)',
      );
    },
    onUpgrade: (db, oldVersion, _) async {
      if (oldVersion < 2) await _ensureContributionAccountColumns(db);
    },
  );

  static Future<void> _ensureContributionAccountColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(goalContributions)');
    final names = columns.map((column) => column['name']).toSet();
    for (final name in const [
      'sourceAccountId',
      'goalAccountId',
      'transferId',
    ]) {
      if (!names.contains(name)) {
        await db.execute('ALTER TABLE goalContributions ADD COLUMN $name TEXT');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    final rows = await (await database).query(
      'goals',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return LocalDataCipher.instance.unprotectRows('goals', rows);
  }

  Future<List<Map<String, dynamic>>> getContributions(String userId) async {
    final rows = await (await database).query(
      'goalContributions',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('goalContributions', rows);
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

  Future<void> deleteContributionsForGoal(String goalId, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'goalContributions',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'goalId = ? AND userId = ? AND deletedAt IS NULL',
      whereArgs: [goalId, userId],
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
