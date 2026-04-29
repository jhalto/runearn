import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionDB {
  static Future<Database>? _db;

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
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL;'); // 🚀 better performance
      },

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
    try {
      final db = await database;
      await db.insert(
        'transactions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("DB Insert Error: $e");
    }
  }

  // 📤 GET ALL
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;

    return await db.query('transactions', orderBy: 'date DESC');
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
  static Future<List<Map<String, dynamic>>> getByCategory(
    String category,
  ) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }
  // update

  static Future<void> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;

    await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🗑 DELETE
  static Future<void> deleteTransaction(String id) async {
    final db = await database;

    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ⚠️ OPTIONAL: CLEAR ALL DATA
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
