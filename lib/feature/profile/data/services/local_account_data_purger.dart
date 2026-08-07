import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:runearn/core/notifications/finance_notification_service.dart';
import 'package:runearn/core/security/local_data_cipher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LocalAccountDataPurger {
  const LocalAccountDataPurger(this.notifications);

  final FinanceNotificationService notifications;

  static const _databaseTables = <String, List<String>>{
    'transactions.db': ['transactions'],
    'accounts.db': ['accountTransfers', 'accounts'],
    'budgets.db': ['budgets'],
    'goals.db': ['goalContributions', 'goals'],
    'recurring.db': ['recurringTransactions'],
    'loans.db': ['loanPayments', 'loans'],
    'tours.db': ['tourCollections', 'tourExpenses', 'tours'],
  };

  Future<void> purge(String userId) async {
    await notifications.cancelFinanceReminders();
    final databaseDirectory = await getDatabasesPath();

    for (final entry in _databaseTables.entries) {
      final path = p.join(databaseDirectory, entry.key);
      if (!await databaseExists(path)) continue;
      final database = await openDatabase(path);
      try {
        if (entry.key == 'transactions.db') {
          await _deleteLocalReceipts(database, userId);
        }
        await database.transaction((transaction) async {
          for (final table in entry.value) {
            if (await _tableExists(transaction, table)) {
              await transaction.delete(
                table,
                where: 'userId = ?',
                whereArgs: [userId],
              );
            }
          }
        });
      } finally {
        // sqflite may return a shared handle owned by an existing data source.
        // Do not close it here; the authenticated session is about to end.
      }
    }

    await (await SharedPreferences.getInstance()).clear();
    await LocalDataCipher.instance.deleteKey();
  }

  Future<void> _deleteLocalReceipts(Database database, String userId) async {
    if (!await _tableExists(database, 'transactions')) return;
    final rows = await database.query(
      'transactions',
      columns: ['id', 'userId', 'localReceiptPath'],
      where: 'userId = ? AND localReceiptPath IS NOT NULL',
      whereArgs: [userId],
    );
    final clearRows = await LocalDataCipher.instance.unprotectRows(
      'transactions',
      rows,
    );
    for (final row in clearRows) {
      final path = row['localReceiptPath'];
      if (path is! String || path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<bool> _tableExists(DatabaseExecutor database, String table) async {
    final rows = await database.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [table],
    );
    return rows.isNotEmpty;
  }
}
