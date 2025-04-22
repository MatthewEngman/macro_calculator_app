import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:macro_masher/src/core/persistence/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Ensure a clean state before each test
    DatabaseHelper.resetForTest();
  });

  test('getInstance returns a valid database', () async {
    final db = await DatabaseHelper.getInstance();
    expect(db, isNotNull);
    expect(await db.getVersion(), isNonNegative);
  });

  test('getInstance returns the same instance if database is valid', () async {
    final db1 = await DatabaseHelper.getInstance();
    final db2 = await DatabaseHelper.getInstance();
    expect(db1, equals(db2));
  });

  test(
    'getInstance recreates database if current instance is invalid',
    () async {
      final db1 = await DatabaseHelper.getInstance();
      // Simulate invalid database by closing it
      await db1.close();
      // Next call should create a new instance
      final db2 = await DatabaseHelper.getInstance();
      expect(db2, isNot(equals(db1)));
      expect(db2.isOpen, isTrue);
    },
  );

  test('database is writable after creation', () async {
    final db = await DatabaseHelper.getInstance();
    await db.execute(
      'CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, value TEXT)',
    );
    final id = await db.insert('test_table', {'value': 'foo'});
    final result = await db.query(
      'test_table',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(result, isNotEmpty);
    expect(result.first['value'], 'foo');
  });

  test('database version matches expected', () async {
    final db = await DatabaseHelper.getInstance();
    expect(await db.getVersion(), DatabaseHelper.databaseVersion);
  });

  test('multiple getInstance calls after close create new instances', () async {
    final db1 = await DatabaseHelper.getInstance();
    await db1.close();
    final db2 = await DatabaseHelper.getInstance();
    expect(db2, isNot(equals(db1)));
    expect(db2.isOpen, isTrue);
  });

  test('getInstance recovers if database file is deleted', () async {
    final db1 = await DatabaseHelper.getInstance();
    final path = db1.path;
    await db1.close();
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    final db2 = await DatabaseHelper.getInstance();
    expect(db2.isOpen, isTrue);
  });
  test('table and column constants are correct', () {
    expect(DatabaseHelper.tableSettings, 'settings');
    expect(DatabaseHelper.columnKey, 'key');
    // ...add more as needed
  });
}
