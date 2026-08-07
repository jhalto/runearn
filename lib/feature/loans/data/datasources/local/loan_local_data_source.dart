import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

abstract interface class LoanLocalDataSource {
  Future<List<Map<String, dynamic>>> getLoans(String userId);
  Future<List<Map<String, dynamic>>> getPendingLoans(String userId);
  Future<void> upsert(Map<String, dynamic> data);
  Future<void> softDelete(String id, String userId);
  Future<void> markAsSynced(String id, String userId);
  Future<void> softDeleteAll(String userId);
  Future<List<Map<String, dynamic>>> getPayments(String userId);
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId);
  Future<void> upsertPayment(Map<String, dynamic> data);
  Future<void> deletePayment(String id, String userId);
  Future<void> markPaymentSynced(String id, String userId);
  Future<void> deletePaymentsForLoan(String loanId, String userId);
}

class LoanLocalDataSourceImpl implements LoanLocalDataSource {
  static Future<Database>? _database;

  Future<Database> get database async {
    _database ??= _openDatabase();
    try {
      return await _database!;
    } catch (_) {
      // Do not permanently cache a failed open operation. This allows a
      // subsequent navigation to retry after a transient database failure.
      _database = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'loans.db');
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        // journal_mode returns a result row, so Android requires rawQuery.
        await db.rawQuery('PRAGMA journal_mode=WAL');
      },
      onOpen: (db) async {
        await LocalDataCipher.instance.migrateTable(db, 'loans');
        await LocalDataCipher.instance.migrateTable(db, 'loanPayments');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE loans (
            id TEXT NOT NULL,
            userId TEXT NOT NULL,
            personName TEXT NOT NULL,
            amount REAL NOT NULL,
            direction TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            issuedAt TEXT NOT NULL,
            dueAt TEXT,
            isSettled INTEGER NOT NULL DEFAULT 0,
            annualInterestRate REAL NOT NULL DEFAULT 0,
            interestMethod TEXT NOT NULL DEFAULT 'none',
            reminderEnabled INTEGER NOT NULL DEFAULT 1,
            reminderDaysBefore INTEGER NOT NULL DEFAULT 1,
            isSynced INTEGER NOT NULL DEFAULT 0,
            updatedAt TEXT NOT NULL,
            deletedAt TEXT,
            PRIMARY KEY (id, userId)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_loans_user_direction '
          'ON loans(userId, direction)',
        );
        await db.execute(
          'CREATE INDEX idx_loans_sync ON loans(userId, isSynced)',
        );
        await _createPaymentsTable(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _createPaymentsTable(db);
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE loans ADD COLUMN annualInterestRate REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE loans ADD COLUMN interestMethod TEXT NOT NULL DEFAULT 'none'",
          );
          await db.execute(
            'ALTER TABLE loans ADD COLUMN reminderEnabled INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE loans ADD COLUMN reminderDaysBefore INTEGER NOT NULL DEFAULT 1',
          );
        }
      },
    );
  }

  static Future<void> _createPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS loanPayments (
        id TEXT NOT NULL,
        userId TEXT NOT NULL,
        loanId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        updatedAt TEXT NOT NULL,
        deletedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id, userId)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_loan '
      'ON loanPayments(userId, loanId, date)',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLoans(String userId) async {
    final db = await database;
    final rows = await db.query(
      'loans',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'isSettled ASC, issuedAt DESC',
    );
    return LocalDataCipher.instance.unprotectRows('loans', rows);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingLoans(String userId) async {
    final db = await database;
    final rows = await db.query(
      'loans',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows('loans', rows);
  }

  @override
  Future<void> upsert(Map<String, dynamic> data) async {
    final db = await database;
    final protected = await LocalDataCipher.instance.protectMap(
      'loans',
      _sqliteCompatible(data),
    );
    await db.insert(
      'loans',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> softDelete(String id, String userId) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'loans',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<void> markAsSynced(String id, String userId) async {
    final db = await database;
    await db.update(
      'loans',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<void> softDeleteAll(String userId) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'loans',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
    );
    await db.update(
      'loanPayments',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPayments(String userId) async {
    final rows = await (await database).query(
      'loanPayments',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('loanPayments', rows);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId) async {
    final rows = await (await database).query(
      'loanPayments',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return LocalDataCipher.instance.unprotectRows('loanPayments', rows);
  }

  @override
  Future<void> upsertPayment(Map<String, dynamic> data) async {
    final protected = await LocalDataCipher.instance.protectMap(
      'loanPayments',
      _sqliteCompatible(data),
    );
    await (await database).insert(
      'loanPayments',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deletePayment(String id, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'loanPayments',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<void> markPaymentSynced(String id, String userId) async {
    await (await database).update(
      'loanPayments',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<void> deletePaymentsForLoan(String loanId, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await database).update(
      'loanPayments',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: 'loanId = ? AND userId = ? AND deletedAt IS NULL',
      whereArgs: [loanId, userId],
    );
  }
}

/// sqflite accepts numbers, strings, byte arrays, and null, but not Dart
/// booleans. Remote Firestore records legitimately use bool values, so
/// normalize them at the local persistence boundary before every insert.
Map<String, dynamic> _sqliteCompatible(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, value is bool ? (value ? 1 : 0) : value),
  );
}
