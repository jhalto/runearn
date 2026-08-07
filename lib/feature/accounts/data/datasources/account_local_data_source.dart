import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class AccountLocalDataSource {
  static Future<Database>? _database;

  Future<Database> get database => _database ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'accounts.db');
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) => db.rawQuery('PRAGMA journal_mode=WAL'),
      onOpen: (db) async {
        await _ensureCurrencyColumns(db);
        await _ensureCreditCardColumns(db);
        await LocalDataCipher.instance.migrateTable(db, 'accounts');
        await LocalDataCipher.instance.migrateTable(db, 'accountTransfers');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE accounts (
            id TEXT NOT NULL,
            userId TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            currencyCode TEXT NOT NULL DEFAULT 'BDT',
            creditLimit REAL,
            statementDay INTEGER,
            paymentDueDay INTEGER,
            minimumPaymentPercent REAL NOT NULL DEFAULT 5,
            minimumPaymentAmount REAL NOT NULL DEFAULT 0,
            paymentReminderEnabled INTEGER NOT NULL DEFAULT 1,
            paymentReminderDaysBefore INTEGER NOT NULL DEFAULT 3,
            updatedAt TEXT NOT NULL,
            deletedAt TEXT,
            isSynced INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (id, userId)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_accounts_user ON accounts(userId, type)',
        );
        await _createTransfersTable(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        await migrateSchema(db, oldVersion);
      },
    );
  }

  static Future<void> migrateSchema(Database db, int oldVersion) async {
    if (oldVersion < 2) await _createTransfersTable(db);
    if (oldVersion < 3) await _ensureCurrencyColumns(db);
    if (oldVersion < 4) await _ensureCreditCardColumns(db);
  }

  static Future<void> _createTransfersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accountTransfers (
        id TEXT NOT NULL,
        userId TEXT NOT NULL,
        fromAccountId TEXT NOT NULL,
        toAccountId TEXT NOT NULL,
        amount REAL NOT NULL,
        receivedAmount REAL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        updatedAt TEXT NOT NULL,
        deletedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id, userId)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transfers_user '
      'ON accountTransfers(userId, date)',
    );
  }

  static Future<void> _ensureCurrencyColumns(Database db) async {
    final accountColumns = await db.rawQuery('PRAGMA table_info(accounts)');
    if (!accountColumns.any((column) => column['name'] == 'currencyCode')) {
      await db.execute(
        "ALTER TABLE accounts ADD COLUMN currencyCode TEXT NOT NULL DEFAULT 'BDT'",
      );
    }
    final transferColumns = await db.rawQuery(
      'PRAGMA table_info(accountTransfers)',
    );
    if (!transferColumns.any((column) => column['name'] == 'receivedAmount')) {
      await db.execute(
        'ALTER TABLE accountTransfers ADD COLUMN receivedAmount REAL',
      );
    }
  }

  static Future<void> _ensureCreditCardColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(accounts)');
    final names = columns.map((column) => column['name']).toSet();
    const additions = <String, String>{
      'creditLimit': 'REAL',
      'statementDay': 'INTEGER',
      'paymentDueDay': 'INTEGER',
      'minimumPaymentPercent': 'REAL NOT NULL DEFAULT 5',
      'minimumPaymentAmount': 'REAL NOT NULL DEFAULT 0',
      'paymentReminderEnabled': 'INTEGER NOT NULL DEFAULT 1',
      'paymentReminderDaysBefore': 'INTEGER NOT NULL DEFAULT 3',
    };
    for (final entry in additions.entries) {
      if (!names.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE accounts ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String userId) async {
    final rows = await (await database).query(
      'accounts',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'type ASC, name ASC',
    );
    final clearRows = await LocalDataCipher.instance.unprotectRows(
      'accounts',
      rows,
    );
    clearRows.sort((left, right) {
      final typeOrder = (left['type'] as String).compareTo(
        right['type'] as String,
      );
      if (typeOrder != 0) return typeOrder;
      return (left['name'] as String).toLowerCase().compareTo(
        (right['name'] as String).toLowerCase(),
      );
    });
    return clearRows;
  }

  Future<List<Map<String, dynamic>>> getPending(String userId) async {
    final rows = await (await database).query(
      'accounts',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows('accounts', rows);
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(
      'accounts',
      data,
    );
    await (await database).insert(
      'accounts',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDelete(String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'accounts',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> markSynced(String id, String userId) async {
    await (await database).update(
      'accounts',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getTransfers(String userId) async {
    final rows = await (await database).query(
      'accountTransfers',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('accountTransfers', rows);
  }

  Future<List<Map<String, dynamic>>> getPendingTransfers(String userId) async {
    final rows = await (await database).query(
      'accountTransfers',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows('accountTransfers', rows);
  }

  Future<void> upsertTransfer(Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(
      'accountTransfers',
      data,
    );
    await (await database).insert(
      'accountTransfers',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransfer(String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'accountTransfers',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> markTransferSynced(String id, String userId) async {
    await (await database).update(
      'accountTransfers',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}
