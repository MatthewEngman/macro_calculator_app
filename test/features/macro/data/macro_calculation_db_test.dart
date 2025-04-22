import 'package:flutter_test/flutter_test.dart';
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/calculator/domain/entities/macro_result.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

// Mock classes
class MockDatabaseHelper extends Mock implements IDatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MacroCalculationDB macroCalculationDB;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    macroCalculationDB = MacroCalculationDB(dbHelper: mockDbHelper);

    // Default: getInstance returns a mock DB
    when(
      () => mockDbHelper.getInstance(),
    ).thenAnswer((_) async => mockDatabase);
    when(() => mockDbHelper.forceRecreateDatabase()).thenAnswer((_) async {});
    when(() => mockDbHelper.verifyDatabaseWritable()).thenAnswer((_) async {});

    // Fallback for any query calls not otherwise stubbed
    when(
      () => mockDatabase.query(
        any(),
        columns: any(named: 'columns'),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        groupBy: any(named: 'groupBy'),
        having: any(named: 'having'),
        orderBy: any(named: 'orderBy'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <Map<String, Object?>>[]);
  });

  test('inserts a macro calculation', () async {
    // Arrange
    final macro = MacroResult(
      id: '123',
      calories: 2000,
      protein: 100,
      carbs: 200,
      fat: 100,
      calculationType: 'standard',
      timestamp: DateTime.now(),
      isDefault: false,
      name: 'Test Calculation',
      lastModified: DateTime.now(),
      userId: 'testUserId',
    );
    when(
      () => mockDatabase.insert(
        any(),
        any(),
        conflictAlgorithm: any(named: 'conflictAlgorithm'),
      ),
    ).thenAnswer((_) async => 1);

    // Act
    final result = await macroCalculationDB.insertCalculation(
      macro,
      'testUserId',
    );

    // Assert
    expect(result, isNotNull);
    verify(
      () => mockDatabase.insert(
        any(),
        any(),
        conflictAlgorithm: any(named: 'conflictAlgorithm'),
      ),
    ).called(1);
  });

  test('retrieves a macro calculation by id', () async {
    // Arrange
    final macroId = '123';
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = <Map<String, Object?>>[
      {
        'id': '123',
        'calories': 2000.0,
        'protein': 100.0,
        'carbs': 200.0,
        'fat': 100.0,
        'calculation_type': 'standard',
        'created_at': now,
        'is_default': 0,
        'name': 'Test Calculation',
        'last_modified': now,
        'user_id': 'testUserId',
      },
    ];
    when(
      () => mockDatabase.query(
        any(),
        columns: any(named: 'columns'),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        groupBy: any(named: 'groupBy'),
        having: any(named: 'having'),
        orderBy: any(named: 'orderBy'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => maps);

    // Act
    final result = await macroCalculationDB.getCalculationById(macroId);

    // Assert
    expect(result, isNotNull);
    expect(result!.id, equals('123'));
    expect(result.calories, equals(2000.0));
    expect(result.protein, equals(100.0));
    expect(result.carbs, equals(200.0));
    expect(result.fat, equals(100.0));
    expect(result.calculationType, equals('standard'));
    expect(result.isDefault, isFalse);
    expect(result.name, equals('Test Calculation'));
    expect(result.userId, equals('testUserId'));
  });

  test('updates a macro calculation', () async {
    // Arrange
    final macro = MacroResult(
      id: '123',
      calories: 2100,
      protein: 110,
      carbs: 220,
      fat: 110,
      calculationType: 'standard',
      timestamp: DateTime.now(),
      isDefault: false,
      name: 'Test Calculation',
      lastModified: DateTime.now(),
      userId: 'testUserId',
    );
    final now = DateTime.now().millisecondsSinceEpoch;

    // Mock update
    when(
      () => mockDatabase.update(
        any(),
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      ),
    ).thenAnswer((_) async => 1);

    // Simulate that getCalculationById returns a record (so update is attempted)
    when(
      () => mockDatabase.query(
        any(),
        columns: any(named: 'columns'),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        groupBy: any(named: 'groupBy'),
        having: any(named: 'having'),
        orderBy: any(named: 'orderBy'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        {
          'id': '123',
          'calories': 2000.0,
          'protein': 100.0,
          'carbs': 200.0,
          'fat': 100.0,
          'calculation_type': 'standard',
          'created_at': now,
          'is_default': 0,
          'name': 'Test Calculation',
          'last_modified': now,
          'user_id': 'testUserId',
        },
      ],
    );

    // Mock insert for fallback (must match all named args)
    when(
      () => mockDatabase.insert(
        any(),
        any(),
        nullColumnHack: any(named: 'nullColumnHack'),
        conflictAlgorithm: any(named: 'conflictAlgorithm'),
      ),
    ).thenAnswer((_) async => 1);

    // Act
    final result = await macroCalculationDB.updateCalculation(
      macro,
      userId: 'testUserId',
    );

    // Assert
    expect(result, isTrue);
    verify(
      () => mockDatabase.update(
        any(),
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      ),
    ).called(1);
  });
  test('deletes a macro calculation', () async {
    // Arrange
    final macroId = '123';
    when(
      () => mockDatabase.delete(
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      ),
    ).thenAnswer((_) async => 1); // 1 row deleted

    // Act
    final result = await macroCalculationDB.deleteCalculation(macroId);

    // Assert
    expect(result, isTrue); // Should be true if 1 row was deleted
    verify(
      () => mockDatabase.delete(
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      ),
    ).called(1);
  });

  test('returns cached calculation if database fails', () async {
    final macro = MacroResult(
      id: 'cachedId',
      calories: 1800,
      protein: 90,
      carbs: 180,
      fat: 80,
      calculationType: 'standard',
      timestamp: DateTime.now(),
      isDefault: false,
      name: 'Cached Calculation',
      lastModified: DateTime.now(),
      userId: 'testUserId',
    );
    MacroCalculationDB.setCalculationsCache('testUserId', [macro]);
    print('CACHE BEFORE LOOKUP: ${MacroCalculationDB.calculationsCache}');
    when(
      () => mockDatabase.query(
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      ),
    ).thenThrow(Exception('Database error'));

    final result = await macroCalculationDB.getCalculationById('cachedId');

    // Additional debug: check what is in the cache and how ids compare
    for (final userCalcs in MacroCalculationDB.calculationsCache.values) {
      for (final c in userCalcs) {
        print(
          'Cache contains MacroResult with id: ${c.id} (type: ${c.id.runtimeType})',
        );
        print(
          'Comparing to requested id: cachedId (type: ${'cachedId'.runtimeType})',
        );
        print('Equality: ${c.id == 'cachedId'}');
      }
    }
    print('RESULT: $result');

    expect(result, isNotNull);
    expect(result!.id, equals('cachedId'));
    expect(result.name, equals('Cached Calculation'));
    MacroCalculationDB.clearCalculationsCache('testUserId');
  });
}
