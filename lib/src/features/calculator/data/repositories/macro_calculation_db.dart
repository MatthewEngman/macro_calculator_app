import 'package:sqflite/sqflite.dart';
import '../../domain/entities/macro_result.dart';
import '../../../../core/persistence/database_helper.dart';

class MacroCalculationDB {
  MacroCalculationDB();

  static const String tableName = 'macro_calculations';

  // Column names (align with main.dart schema)
  static const String columnId = 'id';
  static const String columnUserId = 'user_id'; // Use user_id (FK)
  static const String columnCalories = 'calories';
  static const String columnProtein = 'protein';
  static const String columnCarbs = 'carbs';
  static const String columnFat = 'fat';
  static const String columnCalculationType = 'calculation_type';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsDefault = 'is_default';
  static const String columnName = 'name';
  static const String columnLastModified = 'last_modified';

  // In-memory cache for critical data
  static final Map<String, MacroResult> _defaultCalculationCache = {};
  static final Map<String, List<MacroResult>> _calculationsCache = {};

  // Helper method to validate if a macro result has valid values
  bool _isValidMacroResult(MacroResult result) {
    return result.calories > 0 &&
        result.protein > 0 &&
        result.carbs > 0 &&
        result.fat > 0;
  }

  /// Generic method to execute database operations with automatic recovery
  /// This handles both read-only errors and database closure errors
  Future<T> executeWithRecovery<T>(
    Future<T> Function(Database db) operation,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Always get the latest database instance
        final db = await DatabaseHelper.getInstance();
        return await operation(db);
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        print('Database error in executeWithRecovery: $e');

        if (errorMsg.contains('read-only') ||
            errorMsg.contains('database_closed') ||
            errorMsg.contains('database is closed')) {
          print(
            'Attempting database recovery, retry ${retryCount + 1}/$maxRetries',
          );

          try {
            // Get a fresh database instance with aggressive recovery
            // Always use force recreation for read-only errors
            await DatabaseHelper.verifyDatabaseWritable(forceRecreate: true);

            retryCount++;

            // Small delay before retry to allow system to stabilize
            await Future.delayed(Duration(milliseconds: 300));
            continue; // Retry the operation with the recovered database
          } catch (recoveryError) {
            print('Recovery attempt failed: $recoveryError');
            if (retryCount >= maxRetries - 1) {
              throw Exception(
                'Database recovery failed after $maxRetries attempts: $e',
              );
            }
          }
        } else {
          // For other errors, just rethrow
          rethrow;
        }
      }
      retryCount++;
    }

    throw Exception('Database operation failed after $maxRetries attempts');
  }

  Future<String> insertCalculation(
    MacroResult result, {
    required String userId, // Require userId
  }) async {
    final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final createdAt = now;
    final updatedAt = now;
    final lastModified = result.lastModified?.millisecondsSinceEpoch ?? now;

    // Round macro values to 2 decimal places
    final roundedCalories = double.parse(result.calories.toStringAsFixed(2));
    final roundedProtein = double.parse(result.protein.toStringAsFixed(2));
    final roundedCarbs = double.parse(result.carbs.toStringAsFixed(2));
    final roundedFat = double.parse(result.fat.toStringAsFixed(2));

    final Map<String, dynamic> row = {
      columnId: id,
      columnUserId: userId, // Use userId
      columnCalories: roundedCalories,
      columnProtein: roundedProtein,
      columnCarbs: roundedCarbs,
      columnFat: roundedFat,
      columnCalculationType:
          result.calculationType, // Store the String? value directly
      columnCreatedAt: createdAt, // Use createdAt
      columnUpdatedAt: updatedAt, // Use updatedAt
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      columnLastModified: lastModified,
    };

    // Try a more direct approach for critical operations
    try {
      // Get a fresh database instance
      final db = await DatabaseHelper.getInstance();

      // Try the operation directly
      await db.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print(
        'MacroCalculationDB: Inserted calculation $id for user $userId (direct)',
      );

      // Update the in-memory cache
      final resultWithId = MacroResult(
        id: id,
        calories: roundedCalories,
        protein: roundedProtein,
        carbs: roundedCarbs,
        fat: roundedFat,
        calculationType: result.calculationType,
        isDefault: result.isDefault,
        name: result.name,
        lastModified: DateTime.fromMillisecondsSinceEpoch(lastModified),
      );

      // Only cache valid calculations
      if (_isValidMacroResult(resultWithId)) {
        if (result.isDefault) {
          _defaultCalculationCache[userId] = resultWithId;
          print(
            'MacroCalculationDB: Updated default calculation cache for user $userId',
          );
        }

        if (_calculationsCache.containsKey(userId)) {
          // Remove any existing calculation with the same ID
          _calculationsCache[userId]!.removeWhere((calc) => calc.id == id);
          // Add the new calculation
          _calculationsCache[userId]!.add(resultWithId);
        } else {
          _calculationsCache[userId] = [resultWithId];
        }
        print(
          'MacroCalculationDB: Updated calculations cache for user $userId',
        );
      } else {
        print(
          'MacroCalculationDB: Not caching invalid calculation (zero values)',
        );
      }

      return id;
    } catch (e) {
      print('Direct insert failed: $e');

      // If direct approach fails, try to force recreate the database
      try {
        await DatabaseHelper.verifyDatabaseWritable(forceRecreate: true);
        final db = await DatabaseHelper.getInstance();

        // Try the operation again with the fresh database
        await db.insert(
          tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        print(
          'MacroCalculationDB: Inserted calculation $id for user $userId (after recreation)',
        );

        // Update the in-memory cache
        final resultWithId = MacroResult(
          id: id,
          calories: roundedCalories,
          protein: roundedProtein,
          carbs: roundedCarbs,
          fat: roundedFat,
          calculationType: result.calculationType,
          isDefault: result.isDefault,
          name: result.name,
          lastModified: DateTime.fromMillisecondsSinceEpoch(lastModified),
        );

        // Only cache valid calculations
        if (_isValidMacroResult(resultWithId)) {
          if (result.isDefault) {
            _defaultCalculationCache[userId] = resultWithId;
            print(
              'MacroCalculationDB: Updated default calculation cache for user $userId',
            );
          }

          if (_calculationsCache.containsKey(userId)) {
            // Remove any existing calculation with the same ID
            _calculationsCache[userId]!.removeWhere((calc) => calc.id == id);
            // Add the new calculation
            _calculationsCache[userId]!.add(resultWithId);
          } else {
            _calculationsCache[userId] = [resultWithId];
          }
          print(
            'MacroCalculationDB: Updated calculations cache for user $userId',
          );
        } else {
          print(
            'MacroCalculationDB: Not caching invalid calculation (zero values)',
          );
        }

        return id;
      } catch (e2) {
        print('Insert failed even after database recreation: $e2');

        // As a last resort, just update the in-memory cache
        final resultWithId = MacroResult(
          id: id,
          calories: roundedCalories,
          protein: roundedProtein,
          carbs: roundedCarbs,
          fat: roundedFat,
          calculationType: result.calculationType,
          isDefault: result.isDefault,
          name: result.name,
          lastModified: DateTime.fromMillisecondsSinceEpoch(lastModified),
        );

        // Only cache valid calculations
        if (_isValidMacroResult(resultWithId)) {
          if (result.isDefault) {
            _defaultCalculationCache[userId] = resultWithId;
            print(
              'MacroCalculationDB: Updated default calculation cache for user $userId',
            );
          }

          if (_calculationsCache.containsKey(userId)) {
            // Remove any existing calculation with the same ID
            _calculationsCache[userId]!.removeWhere((calc) => calc.id == id);
            // Add the new calculation
            _calculationsCache[userId]!.add(resultWithId);
          } else {
            _calculationsCache[userId] = [resultWithId];
          }
          print(
            'MacroCalculationDB: Updated calculations cache for user $userId',
          );
        } else {
          print(
            'MacroCalculationDB: Not caching invalid calculation (zero values)',
          );
        }

        print('Updated in-memory cache as fallback for user $userId');
        return id;
      }
    }
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

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAt = now;
    final lastModified = now; // Always update lastModified on successful update

    // Round macro values to 2 decimal places
    final roundedCalories = double.parse(result.calories.toStringAsFixed(2));
    final roundedProtein = double.parse(result.protein.toStringAsFixed(2));
    final roundedCarbs = double.parse(result.carbs.toStringAsFixed(2));
    final roundedFat = double.parse(result.fat.toStringAsFixed(2));

    final Map<String, dynamic> row = {
      columnId: result.id,
      columnUserId: userId, // Use userId
      columnCalories: roundedCalories,
      columnProtein: roundedProtein,
      columnCarbs: roundedCarbs,
      columnFat: roundedFat,
      columnCalculationType:
          result.calculationType, // Store the String? value directly
      columnUpdatedAt: updatedAt, // Update updatedAt
      columnIsDefault: result.isDefault ? 1 : 0,
      columnName: result.name,
      columnLastModified: lastModified, // Update lastModified
    };

    final rowsAffected = await executeWithRecovery(
      (db) => db.update(
        tableName,
        row,
        where: '$columnId = ?', // Update based on primary key
        whereArgs: [result.id],
      ),
    );
    print(
      'MacroCalculationDB: Updated calculation ${result.id}. Rows affected: $rowsAffected',
    );

    // Update the in-memory cache
    final resultWithId = MacroResult(
      id: result.id,
      calories: roundedCalories,
      protein: roundedProtein,
      carbs: roundedCarbs,
      fat: roundedFat,
      calculationType: result.calculationType,
      isDefault: result.isDefault,
      name: result.name,
      lastModified: DateTime.fromMillisecondsSinceEpoch(lastModified),
    );

    // Only cache valid calculations
    if (_isValidMacroResult(resultWithId)) {
      if (result.isDefault) {
        _defaultCalculationCache[userId] = resultWithId;
      }

      if (_calculationsCache.containsKey(userId)) {
        // Remove any existing calculation with the same ID
        _calculationsCache[userId]!.removeWhere((calc) => calc.id == result.id);
        // Add the new calculation
        _calculationsCache[userId]!.add(resultWithId);
      } else {
        _calculationsCache[userId] = [resultWithId];
      }
    } else {
      print(
        'MacroCalculationDB: Not caching invalid calculation (zero values)',
      );
    }

    return rowsAffected > 0;
  }

  Future<List<MacroResult>> getAllCalculations({
    required String userId, // Require userId
  }) async {
    // First check the in-memory cache
    if (_calculationsCache.containsKey(userId)) {
      print(
        'MacroCalculationDB: Retrieved calculations from in-memory cache for user $userId',
      );
      return _calculationsCache[userId]!;
    }

    final List<Map<String, dynamic>> maps = await executeWithRecovery(
      (db) => db.query(
        tableName,
        where: '$columnUserId = ?', // Query by userId
        whereArgs: [userId],
        orderBy: '$columnLastModified DESC', // Order by lastModified
      ),
    );

    if (maps.isEmpty) return [];

    final results = List.generate(maps.length, (i) {
      return MacroResult.fromMap(maps[i]);
    });

    // Update the in-memory cache
    _calculationsCache[userId] = results;

    return results;
  }

  Future<MacroResult?> getCalculationById(String id) async {
    final List<Map<String, dynamic>> maps = await executeWithRecovery(
      (db) => db.query(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
        limit: 1,
      ),
    );

    if (maps.isEmpty) return null;

    return MacroResult.fromMap(maps.first);
  }

  Future<MacroResult?> getDefaultCalculation({
    required String userId, // Require userId
  }) async {
    // First check the in-memory cache
    if (_defaultCalculationCache.containsKey(userId)) {
      final cachedResult = _defaultCalculationCache[userId];

      // Verify the cached result is valid
      if (_isValidMacroResult(cachedResult!)) {
        print(
          'MacroCalculationDB: Retrieved valid default calculation from in-memory cache for user $userId',
        );
        print(
          'Cached Macros: ${cachedResult.calories} kcal, ${cachedResult.protein}g protein',
        );
        return cachedResult;
      } else {
        print(
          'MacroCalculationDB: Found invalid cached calculation with zero values, will try database',
        );
      }
    }

    // Try a more direct approach for critical operations
    try {
      // Get a fresh database instance
      final db = await DatabaseHelper.getInstance();

      // Try the operation directly
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where:
            '$columnUserId = ? AND $columnIsDefault = ?', // Query by userId and isDefault
        whereArgs: [userId, 1],
        limit: 1, // Limit to 1 result
      );

      if (maps.isEmpty) {
        print(
          'MacroCalculationDB: No default calculation found for user $userId',
        );
        return null;
      }

      final result = MacroResult.fromMap(maps.first);

      // Only update the cache if the result is valid
      if (_isValidMacroResult(result)) {
        // Update the cache
        _defaultCalculationCache[userId] = result;
        print(
          'MacroCalculationDB: Found valid default calculation for user $userId (direct)',
        );
      } else {
        print(
          'MacroCalculationDB: Found invalid default calculation with zero values for user $userId',
        );
      }

      return result;
    } catch (e) {
      print('Direct getDefaultCalculation failed: $e');

      // If direct approach fails, try to force recreate the database
      try {
        await DatabaseHelper.verifyDatabaseWritable(forceRecreate: true);
        final db = await DatabaseHelper.getInstance();

        // Try the operation again with the fresh database
        final List<Map<String, dynamic>> maps = await db.query(
          tableName,
          where:
              '$columnUserId = ? AND $columnIsDefault = ?', // Query by userId and isDefault
          whereArgs: [userId, 1],
          limit: 1, // Limit to 1 result
        );

        if (maps.isEmpty) {
          print(
            'MacroCalculationDB: No default calculation found for user $userId',
          );
          return null;
        }

        final result = MacroResult.fromMap(maps.first);

        // Only update the cache if the result is valid
        if (_isValidMacroResult(result)) {
          // Update the cache
          _defaultCalculationCache[userId] = result;
          print(
            'MacroCalculationDB: Found valid default calculation for user $userId (after recreation)',
          );
        } else {
          print(
            'MacroCalculationDB: Found invalid default calculation with zero values for user $userId',
          );
        }

        return result;
      } catch (e2) {
        print(
          'getDefaultCalculation failed even after database recreation: $e2',
        );

        // If we have a cached value, return it as a fallback
        if (_defaultCalculationCache.containsKey(userId)) {
          print(
            'MacroCalculationDB: Returning cached default calculation as fallback for user $userId',
          );
          return _defaultCalculationCache[userId];
        }

        return null; // Return null instead of throwing to avoid app crashes
      }
    }
  }

  Future<bool> setDefaultCalculation({
    required String id,
    required String userId, // Require userId
  }) async {
    // First, unset all defaults for this user
    await executeWithRecovery(
      (db) => db.update(
        tableName,
        {
          columnIsDefault: 0,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnUserId = ?', // Filter by userId
        whereArgs: [userId],
      ),
    );

    // Then set the new default
    await executeWithRecovery(
      (db) => db.update(
        tableName,
        {
          columnIsDefault: 1,
          columnLastModified: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnId = ?', // Set by primary key
        whereArgs: [id],
      ),
    );
    print(
      'MacroCalculationDB: Set calculation $id as default for user $userId',
    );

    // Update the in-memory cache
    final calculation = await getCalculationById(id);
    if (calculation != null) {
      _defaultCalculationCache[userId] = calculation;
    }

    return true;
  }

  Future<int> deleteCalculation(String id) async {
    print('MacroCalculationDB: Deleting calculation $id');
    return await executeWithRecovery(
      (db) => db.delete(tableName, where: '$columnId = ?', whereArgs: [id]),
    );
  }
}
