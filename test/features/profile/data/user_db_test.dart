import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements IDatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDatabaseHelper mockDbHelper;
  late UserDB userDB;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    userDB = UserDB(dbHelper: mockDbHelper);

    // Default: getInstance returns a mock DB
    when(
      () => mockDbHelper.getInstance(),
    ).thenAnswer((_) async => mockDatabase);
    when(() => mockDbHelper.forceRecreateDatabase()).thenAnswer((_) async {});
    when(() => mockDbHelper.verifyDatabaseWritable()).thenAnswer((_) async {});
  });

  test('executes operation successfully on first try', () async {
    var called = false;
    final result = await userDB.executeWithRecovery((db) async {
      called = true;
      expect(db, mockDatabase);
      return 42;
    });
    expect(result, 42);
    expect(called, isTrue);
    verify(() => mockDbHelper.getInstance()).called(1);
    verifyNever(() => mockDbHelper.forceRecreateDatabase());
    verifyNever(() => mockDbHelper.verifyDatabaseWritable());
  });

  test('retries on read-only error and succeeds', () async {
    int callCount = 0;
    when(() => mockDbHelper.getInstance()).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) throw Exception('read-only');
      return mockDatabase;
    });

    final result = await userDB.executeWithRecovery((db) async => 99);
    expect(result, 99);
    expect(callCount, 2);
    verify(() => mockDbHelper.verifyDatabaseWritable()).called(1);
    verifyNever(() => mockDbHelper.forceRecreateDatabase());
  });

  test('calls forceRecreateDatabase after repeated failures', () async {
    int callCount = 0;
    // Fail twice, then succeed
    when(() => mockDbHelper.getInstance()).thenAnswer((_) async {
      callCount++;
      if (callCount < 3) throw Exception('read-only');
      return mockDatabase;
    });

    // Force verifyDatabaseWritable to always throw
    when(
      () => mockDbHelper.verifyDatabaseWritable(),
    ).thenThrow(Exception('still read-only'));

    final result = await userDB.executeWithRecovery((db) async => 123);
    expect(result, 123);
    expect(callCount, 3);
    verify(
      () => mockDbHelper.verifyDatabaseWritable(),
    ).called(greaterThanOrEqualTo(2));
    verify(() => mockDbHelper.forceRecreateDatabase()).called(1);
  });

  test('throws after max retries on persistent read-only error', () async {
    when(() => mockDbHelper.getInstance()).thenThrow(Exception('read-only'));
    expect(
      () async => await userDB.executeWithRecovery((db) async => 0),
      throwsA(isA<Exception>()),
    );
    verify(
      () => mockDbHelper.verifyDatabaseWritable(),
    ).called(greaterThanOrEqualTo(1));
    verifyNever(() => mockDbHelper.forceRecreateDatabase());
  });

  test('rethrows non-read-only errors immediately', () async {
    when(
      () => mockDbHelper.getInstance(),
    ).thenThrow(Exception('something else'));
    expect(
      () async => await userDB.executeWithRecovery((db) async => 0),
      throwsA(isA<Exception>()),
    );
    verifyNever(() => mockDbHelper.verifyDatabaseWritable());
    verifyNever(() => mockDbHelper.forceRecreateDatabase());
  });
}
