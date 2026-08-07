import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/accounts/data/datasources/account_local_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'migrates a version-one account database to the current schema',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('''
      CREATE TABLE accounts (
        id TEXT NOT NULL,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        deletedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id, userId)
      )
    ''');

      await AccountLocalDataSource.migrateSchema(db, 1);

      final accountColumns = await db.rawQuery('PRAGMA table_info(accounts)');
      final names = accountColumns.map((column) => column['name']).toSet();
      expect(
        names,
        containsAll([
          'currencyCode',
          'creditLimit',
          'statementDay',
          'paymentDueDay',
          'minimumPaymentPercent',
          'paymentReminderEnabled',
        ]),
      );
      final transferTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='accountTransfers'",
      );
      expect(transferTable, isNotEmpty);
    },
  );
}
