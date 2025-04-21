import 'package:sqflite/sqflite.dart';
import '../../domain/entities/macro_result.dart';

class MacroCalculationDB {
  final Database database;

  MacroCalculationDB({required this.database});

  static const String tableName = 'macro_calculations';

  // Column names (align with main.dart schema)
  static const String columnId = 'id';
  static const String columnUserId = 'user_id'; // Use user_id (FK)
  static const String columnCalories = 'calories';
  static const String columnProtein = 'protein';
  static const String columnCarbs = 'carbs';
  static const String columnFat = 'fat';
  static const String columnCalculationType = 'calculation_type';
  // static const String columnTimestamp = 'timestamp'; // Remove, use created_at/updated_at
  static const String columnCreatedAt = 'created_at'; // Added
  static const String columnUpdatedAt = 'updated_at'; // Added
  static const String columnIsDefault = 'is_default';
  static const String columnName = 'name';
  // static const String columnFirebaseUserId = 'firebase_user_id'; // Remove
  static const String columnLastModified = 'last_modified'; // Keep

  Future<String> insertCalculation(
    MacroResult result, {
    required String userId, // Require userId
  }) async {
    final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    // final timestamp = result.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final createdAt = now;
    final updatedAt = now;
    final lastModified = result.lastModified?.millisecondsSinceEpoch ?? now;

    final Map<String, dynamic> row = {
      columnId: id,
      columnUserId: userId, // Use userId
      columnCalories: result.calories,
      columnProtein: result.protein,
      columnCarbs: result.carbs,
      columnFat: result.fat,
      columnCalculationType:
          result.calculationType, // Store the String? value directly
      columnCreatedAt: createdAt, // Use createdAt
      columnUpdatedAt: updatedAt, // Use updatedAt
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      columnLastModified: lastModified,
    };

    await database.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('MacroCalculationDB: Inserted calculation $id for user $userId');
    return id;
  }

  Future<bool> updateCalculation(
    MacroResult result, {
    required String userId, // Require userId
  }) async {
    if (result.id == null) {
      print(
        'MacroCalculationDB: Cannot update calculation without ID. Inserting instead.',
      );
      await insertCalculation(result, userId: userId);
      return true;
      // throw ArgumentError('Cannot update a calculation without an ID');
    }

    // First check if the record exists and get its current lastModified value
    final existingRecord = await getCalculationById(result.id!);
    if (existingRecord == null) {
      print(
        'MacroCalculationDB: Record ${result.id} not found for update. Inserting instead.',
      );
      // Record doesn't exist, insert it instead
      await insertCalculation(result, userId: userId);
      return true;
    }

    // If the existing record has a newer lastModified timestamp, don't update
    final existingLastModified = existingRecord.lastModified ?? DateTime(1970);
    final newLastModified = result.lastModified ?? DateTime.now();

    // Allow update if the new record is newer or has the same timestamp (idempotency)
    if (existingLastModified.isAfter(newLastModified)) {
      print(
        'MacroCalculationDB: Existing record ${result.id} is newer. Skipping update.',
      );
      // Existing record is newer, don't update
      return false;
    }

    // final timestamp = result.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAt = now;
    final lastModified = now; // Always update lastModified on successful update

    final Map<String, dynamic> row = {
      // Do not update id or userId or createdAt
      columnCalories: result.calories,
      columnProtein: result.protein,
      columnCarbs: result.carbs,
      columnFat: result.fat,
      columnCalculationType:
          result.calculationType, // Store the String? value directly
      // columnTimestamp: timestamp, // Remove
      columnUpdatedAt: updatedAt, // Update updatedAt
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      // columnFirebaseUserId: firebaseUserId, // Remove
      columnLastModified: lastModified, // Update lastModified
    };

    final rowsAffected = await database.update(
      tableName,
      row,
      where: '$columnId = ?', // Update based on primary key
      whereArgs: [result.id],
    );
    print(
      'MacroCalculationDB: Updated calculation ${result.id}. Rows affected: $rowsAffected',
    );
    return rowsAffected > 0;
  }

  // Update to only use userId
  Future<List<MacroResult>> getAllCalculations({
    required String userId, // Require userId
  }) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: '$columnUserId = ?', // Query by userId
      whereArgs: [userId],
      orderBy: '$columnLastModified DESC', // Order by lastModified
    );
    /* // Old logic
    if (userId != null) {
      maps = await database.query(
        tableName,
        where: '$columnUserId = ?',
        whereArgs: [userId],
        orderBy: '$columnTimestamp DESC',
      );
    } else if (firebaseUserId != null) {
      maps = await database.query(
        tableName,
        where: '$columnFirebaseUserId = ?',
        whereArgs: [firebaseUserId],
        orderBy: '$columnTimestamp DESC',
      );
    } else {
      maps = await database.query(tableName, orderBy: '$columnTimestamp DESC');
    }
    */

    if (maps.isEmpty) return [];

    return List.generate(maps.length, (i) {
      // final calculationTypeString = maps[i][columnCalculationType];
      // final calculationType = Goal.values.firstWhere(
      //   (e) => e.toString() == calculationTypeString,
      //   orElse: () => Goal.maintain, // Default value or handle error
      // );
      final calculationType = maps[i][columnCalculationType];

      return MacroResult(
        id: maps[i][columnId],
        calories: maps[i][columnCalories]?.toDouble() ?? 0.0,
        protein: maps[i][columnProtein]?.toDouble() ?? 0.0,
        carbs: maps[i][columnCarbs]?.toDouble() ?? 0.0,
        fat: maps[i][columnFat]?.toDouble() ?? 0.0,
        calculationType: calculationType,
        timestamp:
            maps[i][columnLastModified] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  maps[i][columnLastModified],
                )
                : null,
        lastModified:
            maps[i][columnLastModified] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  maps[i][columnLastModified],
                )
                : null,
        isDefault: maps[i][columnIsDefault] == 1,
        name: maps[i][columnName],
      );
    });
  }

  Future<MacroResult?> getCalculationById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    // final calculationTypeString = maps[0][columnCalculationType];
    // final calculationType = Goal.values.firstWhere(
    //   (e) => e.toString() == calculationTypeString,
    //   orElse: () => Goal.maintain,
    // );
    final calculationType = maps[0][columnCalculationType];

    return MacroResult(
      id: maps[0][columnId],
      calories: maps[0][columnCalories]?.toDouble() ?? 0.0,
      protein: maps[0][columnProtein]?.toDouble() ?? 0.0,
      carbs: maps[0][columnCarbs]?.toDouble() ?? 0.0,
      fat: maps[0][columnFat]?.toDouble() ?? 0.0,
      calculationType: calculationType,
      timestamp:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
      isDefault: maps[0][columnIsDefault] == 1,
      name: maps[0][columnName],
      lastModified:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
    );
  }

  // Update to only use userId
  Future<MacroResult?> getDefaultCalculation({
    required String userId, // Require userId
  }) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: '$columnIsDefault = ? AND $columnUserId = ?', // Query by userId
      whereArgs: [1, userId],
      limit: 1,
    );
    /* // Old logic
    if (userId != null) {
      maps = await database.query(
        tableName,
        where: '$columnIsDefault = ? AND $columnUserId = ?',
        whereArgs: [1, userId],
        limit: 1,
      );
    } else if (firebaseUserId != null) {
      maps = await database.query(
        tableName,
        where: '$columnIsDefault = ? AND $columnFirebaseUserId = ?',
        whereArgs: [1, firebaseUserId],
        limit: 1,
      );
    } else {
      maps = await database.query(
        tableName,
        where: '$columnIsDefault = ?',
        whereArgs: [1],
        limit: 1,
      );
    }
    */

    if (maps.isEmpty) return null;

    // final calculationTypeString = maps[0][columnCalculationType];
    // final calculationType = Goal.values.firstWhere(
    //   (e) => e.toString() == calculationTypeString,
    //   orElse: () => Goal.maintain,
    // );
    final calculationType = maps[0][columnCalculationType];

    return MacroResult(
      id: maps[0][columnId],
      calories: maps[0][columnCalories]?.toDouble() ?? 0.0,
      protein: maps[0][columnProtein]?.toDouble() ?? 0.0,
      carbs: maps[0][columnCarbs]?.toDouble() ?? 0.0,
      fat: maps[0][columnFat]?.toDouble() ?? 0.0,
      calculationType: calculationType,
      timestamp:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
      isDefault: maps[0][columnIsDefault] == 1,
      name: maps[0][columnName],
      lastModified:
          maps[0][columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[0][columnLastModified])
              : null,
    );
  }

  // Update to only use userId
  Future<void> setDefaultCalculation(
    String id, {
    required String userId, // Require userId
  }) async {
    // First, unset all defaults for this user
    await database.update(
      tableName,
      {
        columnIsDefault: 0,
        columnLastModified: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$columnUserId = ?', // Filter by userId
      whereArgs: [userId],
    );
    /* // Old logic
    if (userId != null) {
      await database.update(
        tableName,
        {
          columnIsDefault: 0,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
    } else if (firebaseUserId != null) {
      await database.update(
        tableName,
        {
          columnIsDefault: 0,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnFirebaseUserId = ?',
        whereArgs: [firebaseUserId],
      );
    } else {
      await database.update(tableName, {
        columnIsDefault: 0,
        columnLastModified: DateTime.now().millisecondsSinceEpoch,
      });
    }
    */

    // Then set the new default
    await database.update(
      tableName,
      {
        columnIsDefault: 1,
        columnLastModified: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$columnId = ?', // Set by primary key
      whereArgs: [id],
    );
    print(
      'MacroCalculationDB: Set calculation $id as default for user $userId',
    );
  }

  Future<int> deleteCalculation(String id) async {
    print('MacroCalculationDB: Deleting calculation $id');
    return await database.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
