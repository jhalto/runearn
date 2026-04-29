import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB('transactions.db');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 📌 MAIN TABLE
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            date TEXT NOT NULL
          )
        ''');

        // 🚀 INDEXING (performance boost)
        await db.execute('CREATE INDEX idx_date ON transactions(date)');
        await db.execute('CREATE INDEX idx_category ON transactions(category)');
        await db.execute('CREATE INDEX idx_type ON transactions(type)');
      },
    );
  }

  // 📥 INSERT
  static Future<void> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;

    await db.insert(
      'transactions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // safe overwrite
    );
  }

  // 📤 GET ALL
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;

    return await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
  }

  // 🔍 FILTER BY TYPE (income/expense)
  static Future<List<Map<String, dynamic>>> getByType(String type) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
  }

  // 🔍 FILTER BY CATEGORY
  static Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }

  // 🗑 DELETE
  static Future<void> deleteTransaction(String id) async {
    final db = await database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ⚠️ OPTIONAL: CLEAR ALL DATA
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}