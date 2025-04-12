import 'package:sqflite/sqflite.dart';
import '../../../../core/persistence/database_helper.dart';
import '../../domain/entities/macro_result.dart';

class MacroCalculationDB {
  static const String tableName = 'macro_calculations';

  // Column names
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnCalories = 'calories';
  static const String columnProtein = 'protein';
  static const String columnCarbs = 'carbs';
  static const String columnFat = 'fat';
  static const String columnCalculationType = 'calculation_type';
  static const String columnTimestamp = 'timestamp';
  static const String columnIsDefault = 'is_default';
  static const String columnName = 'name';
  static const String columnFirebaseUserId = 'firebase_user_id';
  static const String columnLastModified = 'last_modified';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnUserId TEXT,
        $columnCalories INTEGER NOT NULL,
        $columnProtein REAL NOT NULL,
        $columnCarbs REAL NOT NULL,
        $columnFat REAL NOT NULL,
        $columnCalculationType TEXT NOT NULL,
        $columnTimestamp INTEGER NOT NULL,
        $columnIsDefault INTEGER NOT NULL DEFAULT 0,
        $columnName TEXT,
        $columnFirebaseUserId TEXT,
        $columnLastModified INTEGER,
        FOREIGN KEY($columnUserId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<String> insertCalculation(
    MacroResult result, {
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp =
        result.timestamp?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final lastModified =
        result.lastModified?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    final Map<String, dynamic> row = {
      columnId: id,
      columnUserId: userId,
      columnCalories: result.calories,
      columnProtein: result.protein,
      columnCarbs: result.carbs,
      columnFat: result.fat,
      columnCalculationType: result.calculationType,
      columnTimestamp: timestamp,
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      columnFirebaseUserId: firebaseUserId,
      columnLastModified: lastModified,
    };

    await db.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  static Future<bool> updateCalculation(
    MacroResult result, {
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (result.id == null) {
      throw ArgumentError('Cannot update a calculation without an ID');
    }

    // First check if the record exists and get its current lastModified value
    final existingRecord = await getCalculationById(result.id!);
    if (existingRecord == null) {
      // Record doesn't exist, insert it instead
      await insertCalculation(
        result,
        userId: userId,
        firebaseUserId: firebaseUserId,
      );
      return true;
    }

    // If the existing record has a newer lastModified timestamp, don't update
    final existingLastModified = existingRecord.lastModified ?? DateTime(1970);
    final newLastModified = result.lastModified ?? DateTime.now();

    if (existingLastModified.isAfter(newLastModified)) {
      // Existing record is newer, don't update
      return false;
    }

    final timestamp =
        result.timestamp?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final lastModified = DateTime.now().millisecondsSinceEpoch;

    final Map<String, dynamic> row = {
      columnCalories: result.calories,
      columnProtein: result.protein,
      columnCarbs: result.carbs,
      columnFat: result.fat,
      columnCalculationType: result.calculationType,
      columnTimestamp: timestamp,
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      columnLastModified: lastModified,
    };

    // Only set user IDs if they are provided
    if (userId != null) {
      row[columnUserId] = userId;
    }
    if (firebaseUserId != null) {
      row[columnFirebaseUserId] = firebaseUserId;
    }

    final rowsAffected = await db.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [result.id],
    );

    return rowsAffected > 0;
  }

  static Future<List<MacroResult>> getAllCalculations({
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '$columnUserId = ?',
        whereArgs: [userId],
        orderBy: '$columnTimestamp DESC',
      );
    } else if (firebaseUserId != null) {
      maps = await db.query(
        tableName,
        where: '$columnFirebaseUserId = ?',
        whereArgs: [firebaseUserId],
        orderBy: '$columnTimestamp DESC',
      );
    } else {
      maps = await db.query(tableName, orderBy: '$columnTimestamp DESC');
    }

    return List.generate(maps.length, (i) {
      return MacroResult(
        id: maps[i][columnId],
        calories: maps[i][columnCalories],
        protein: maps[i][columnProtein],
        carbs: maps[i][columnCarbs],
        fat: maps[i][columnFat],
        calculationType: maps[i][columnCalculationType],
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          maps[i][columnTimestamp],
        ),
        isDefault: maps[i][columnIsDefault] == 1,
        name: maps[i][columnName],
        lastModified:
            maps[i][columnLastModified] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  maps[i][columnLastModified],
                )
                : null,
      );
    });
  }

  static Future<MacroResult?> getCalculationById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return MacroResult(
      id: maps[0][columnId],
      calories: maps[0][columnCalories],
      protein: maps[0][columnProtein],
      carbs: maps[0][columnCarbs],
      fat: maps[0][columnFat],
      calculationType: maps[0][columnCalculationType],
      timestamp: DateTime.fromMillisecondsSinceEpoch(maps[0][columnTimestamp]),
      isDefault: maps[0][columnIsDefault] == 1,
      name: maps[0][columnName],
      lastModified:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
    );
  }

  static Future<MacroResult?> getDefaultCalculation({
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '$columnIsDefault = ? AND $columnUserId = ?',
        whereArgs: [1, userId],
        limit: 1,
      );
    } else if (firebaseUserId != null) {
      maps = await db.query(
        tableName,
        where: '$columnIsDefault = ? AND $columnFirebaseUserId = ?',
        whereArgs: [1, firebaseUserId],
        limit: 1,
      );
    } else {
      maps = await db.query(
        tableName,
        where: '$columnIsDefault = ?',
        whereArgs: [1],
        limit: 1,
      );
    }

    if (maps.isEmpty) return null;

    return MacroResult(
      id: maps[0][columnId],
      calories: maps[0][columnCalories],
      protein: maps[0][columnProtein],
      carbs: maps[0][columnCarbs],
      fat: maps[0][columnFat],
      calculationType: maps[0][columnCalculationType],
      timestamp: DateTime.fromMillisecondsSinceEpoch(maps[0][columnTimestamp]),
      isDefault: maps[0][columnIsDefault] == 1,
      name: maps[0][columnName],
      lastModified:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
    );
  }

  static Future<void> setDefaultCalculation(
    String id, {
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // First, unset all defaults
    if (userId != null) {
      await db.update(
        tableName,
        {
          columnIsDefault: 0,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
    } else if (firebaseUserId != null) {
      await db.update(
        tableName,
        {
          columnIsDefault: 0,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnFirebaseUserId = ?',
        whereArgs: [firebaseUserId],
      );
    } else {
      await db.update(tableName, {
        columnIsDefault: 0,
        columnLastModified: DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Then set the new default
    await db.update(
      tableName,
      {
        columnIsDefault: 1,
        columnLastModified: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteCalculation(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }
}
