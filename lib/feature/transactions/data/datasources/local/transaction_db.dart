import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:runearn/core/security/local_data_cipher.dart';

class TransactionDB {
  static Future<Database>? _db;
  static bool _customCategoryColumnChecked = false;
  static bool _accountIdColumnChecked = false;
  static bool _localReceiptColumnChecked = false;
  static bool _tagsColumnChecked = false;
  static bool _splitsColumnChecked = false;

  static Future<void> init() async {
    await database;
  }

  static Future<Database> get database async {
    _db ??= _initDB('transactions.db');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 6,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL;'); // 🚀 better performance
      },

      onOpen: (db) => LocalDataCipher.instance.migrateTable(db, 'transactions'),
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      customCategory TEXT,
      accountId TEXT,
      description TEXT,
      localReceiptPath TEXT,
      tags TEXT NOT NULL DEFAULT '[]',
      splits TEXT NOT NULL DEFAULT '[]',
      date TEXT NOT NULL,
      isSynced INTEGER NOT NULL DEFAULT 0,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT
  )
  ''');

        await db.execute('CREATE INDEX idx_userId ON transactions(userId)');
        await db.execute('CREATE INDEX idx_date ON transactions(date)');
        await db.execute('CREATE INDEX idx_category ON transactions(category)');
        await db.execute('CREATE INDEX idx_type ON transactions(type)');
        await db.execute('CREATE INDEX idx_synced ON transactions(isSynced)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN customCategory TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN accountId TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN localReceiptPath TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN splits TEXT NOT NULL DEFAULT '[]'",
          );
        }
      },
    );
  }

  // 📥 INSERT
  static Future<void> insertTransaction(Map<String, dynamic> data) async {
    try {
      final db = await database;
      await _ensureCustomCategoryColumn(db);
      await _ensureAccountIdColumn(db);
      await _ensureLocalReceiptColumn(db);
      await _ensureTagsColumn(db);
      await _ensureSplitsColumn(db);

      final protected = await LocalDataCipher.instance
          .protectMap('transactions', {
            ...data,
            'isSynced': data['isSynced'] ?? 0,
            'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
            'deletedAt': data['deletedAt'],
          });
      await db.insert(
        'transactions',
        protected,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("DB Insert Error: $e");
    }
  }

  // 📤 GET ALL
  static Future<List<Map<String, dynamic>>> getTransactions(
    String userId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'transactions',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('transactions', rows);
  }

  // 🔍 FILTER BY TYPE (income/expense)
  static Future<List<Map<String, dynamic>>> getByType(String type) async {
    final db = await database;

    final rows = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('transactions', rows);
  }

  // 🔍 FILTER BY CATEGORY
  static Future<List<Map<String, dynamic>>> getByCategory(
    String category,
  ) async {
    final db = await database;

    final rows = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return LocalDataCipher.instance.unprotectRows('transactions', rows);
  }
  // update

  static Future<void> updateTransaction(
    Map<String, dynamic> data,
    String userId,
  ) async {
    final db = await database;
    await _ensureCustomCategoryColumn(db);
    await _ensureAccountIdColumn(db);
    await _ensureLocalReceiptColumn(db);
    await _ensureTagsColumn(db);
    await _ensureSplitsColumn(db);

    final protected = await LocalDataCipher.instance.protectMap(
      'transactions',
      data,
    );
    await db.update(
      'transactions',
      protected,
      where: 'id = ? AND userId = ?',
      whereArgs: [data['id'], userId],
    );
  }

  // 🗑 DELETE
  static Future<void> deleteTransaction(String id, String userId) async {
    final db = await database;

    await db.update(
      'transactions',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // ⚠️ OPTIONAL: CLEAR ALL DATA
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }

  static Future<void> clearUserTransactions(
    String userId, {
    String? type,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'transactions',
      {'deletedAt': now, 'updatedAt': now, 'isSynced': 0},
      where: type == null
          ? 'userId = ? AND deletedAt IS NULL'
          : 'userId = ? AND type = ? AND deletedAt IS NULL',
      whereArgs: type == null ? [userId] : [userId, type],
    );
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
    _customCategoryColumnChecked = false;
    _accountIdColumnChecked = false;
    _localReceiptColumnChecked = false;
    _tagsColumnChecked = false;
    _splitsColumnChecked = false;
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedTransactions(
    String userId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'transactions',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
    );
    return LocalDataCipher.instance.unprotectRows('transactions', rows);
  }

  static Future<void> markAsSynced(String id, String userId) async {
    final db = await database;

    await db.update(
      'transactions',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final db = await database;
    await _ensureCustomCategoryColumn(db);
    await _ensureAccountIdColumn(db);
    await _ensureLocalReceiptColumn(db);
    await _ensureTagsColumn(db);
    await _ensureSplitsColumn(db);

    final existing = await db.query(
      'transactions',
      columns: ['localReceiptPath'],
      where: 'id = ? AND userId = ?',
      whereArgs: [data['id'], data['userId']],
      limit: 1,
    );
    final localReceiptPath = existing.isEmpty
        ? null
        : existing.first['localReceiptPath'];
    final protected = await LocalDataCipher.instance.protectMap(
      'transactions',
      {...data, 'localReceiptPath': localReceiptPath, 'isSynced': 1},
    );
    await db.insert(
      'transactions',
      protected,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _ensureCustomCategoryColumn(Database db) async {
    if (_customCategoryColumnChecked) return;

    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    final hasColumn = columns.any(
      (column) => column['name'] == 'customCategory',
    );
    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN customCategory TEXT',
      );
    }
    _customCategoryColumnChecked = true;
  }

  static Future<void> _ensureAccountIdColumn(Database db) async {
    if (_accountIdColumnChecked) return;
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    if (!columns.any((column) => column['name'] == 'accountId')) {
      await db.execute('ALTER TABLE transactions ADD COLUMN accountId TEXT');
    }
    _accountIdColumnChecked = true;
  }

  static Future<void> _ensureLocalReceiptColumn(Database db) async {
    if (_localReceiptColumnChecked) return;
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    if (!columns.any((column) => column['name'] == 'localReceiptPath')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN localReceiptPath TEXT',
      );
    }
    _localReceiptColumnChecked = true;
  }

  static Future<void> _ensureTagsColumn(Database db) async {
    if (_tagsColumnChecked) return;
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    if (!columns.any((column) => column['name'] == 'tags')) {
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'",
      );
    }
    _tagsColumnChecked = true;
  }

  static Future<void> _ensureSplitsColumn(Database db) async {
    if (_splitsColumnChecked) return;
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    if (!columns.any((column) => column['name'] == 'splits')) {
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN splits TEXT NOT NULL DEFAULT '[]'",
      );
    }
    _splitsColumnChecked = true;
  }
}
