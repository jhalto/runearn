import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class BudgetLocalDataSource {
  static Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'budgets.db'),
    version: 2,
    onConfigure: (db) => db.rawQuery('PRAGMA journal_mode=WAL'),
    onOpen: (db) async {
      await _ensurePlanningColumns(db);
      await LocalDataCipher.instance.migrateTable(db, 'budgets');
    },
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE budgets (
          id TEXT NOT NULL,
          userId TEXT NOT NULL,
          categoryName TEXT NOT NULL,
          "limit" REAL NOT NULL,
          month TEXT NOT NULL,
          rolloverEnabled INTEGER NOT NULL DEFAULT 0,
          isTemplate INTEGER NOT NULL DEFAULT 0,
          templateName TEXT NOT NULL DEFAULT '',
          updatedAt TEXT NOT NULL,
          deletedAt TEXT,
          isSynced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_budgets_user_month ON budgets(userId, month)',
      );
    },
    onUpgrade: (db, oldVersion, _) async {
      if (oldVersion < 2) await _ensurePlanningColumns(db);
    },
  );

  static Future<void> _ensurePlanningColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(budgets)');
    final names = columns.map((column) => column['name']).toSet();
    const additions = {
      'rolloverEnabled': 'INTEGER NOT NULL DEFAULT 0',
      'isTemplate': 'INTEGER NOT NULL DEFAULT 0',
      'templateName': "TEXT NOT NULL DEFAULT ''",
    };
    for (final entry in additions.entries) {
      if (!names.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE budgets ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String userId) async {
    final rows = await (await database).query(
      'budgets',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'month DESC, categoryName ASC',
    );
    final clearRows = await LocalDataCipher.instance.unprotectRows(
      'budgets',
      rows,
    );
    clearRows.sort((left, right) {
      final monthOrder = (right['month'] as String).compareTo(
        left['month'] as String,
      );
      if (monthOrder != 0) return monthOrder;
      return (left['categoryName'] as String).toLowerCase().compareTo(
        (right['categoryName'] as String).toLowerCase(),
      );
    });
    return clearRows;
  }

  Future<List<Map<String, dynamic>>> getPending(String userId) async {
    final rows = await (await database).query(
      'budgets',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows('budgets', rows);
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(
      'budgets',
      data,
    );
    await (await database).insert(
      'budgets',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDelete(String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'budgets',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> markSynced(String id, String userId) async =>
      (await database).update(
        'budgets',
        {'isSynced': 1},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
}
