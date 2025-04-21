import 'package:sqflite/sqflite.dart';
import '../models/meal_plan.dart';
import '../../../core/persistence/database_helper.dart';

class MealPlanDB {
  MealPlanDB();

  static const String tableName = 'meal_plans';

  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnDate = 'date';
  static const String columnMeals = 'meals';
  static const String columnTotalCalories = 'total_calories';
  static const String columnTotalProtein = 'total_protein';
  static const String columnTotalCarbs = 'total_carbs';
  static const String columnTotalFat = 'total_fat';
  static const String columnNotes = 'notes';
  static const String columnFirebaseUserId = 'firebase_user_id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnLastModified = 'last_modified';

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
            // Get a fresh database instance with aggressive recovery if needed
            await DatabaseHelper.verifyDatabaseWritable();

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

  static Future<void> createTable(Database db) async {
    try {
      await db.rawQuery('''
          CREATE TABLE IF NOT EXISTS $tableName (
            $columnId TEXT PRIMARY KEY, 
            $columnUserId TEXT NOT NULL, 
            $columnDate TEXT, 
            $columnMeals TEXT, 
            $columnTotalCalories REAL, 
            $columnTotalProtein REAL, 
            $columnTotalCarbs REAL, 
            $columnTotalFat REAL, 
            $columnNotes TEXT, 
            $columnFirebaseUserId TEXT, 
            $columnCreatedAt INTEGER, 
            $columnUpdatedAt INTEGER, 
            $columnLastModified INTEGER
          )
          ''');
      print('MealPlanDB: Created $tableName table');
    } catch (e) {
      print('MealPlanDB: Error creating $tableName table: $e');
    }
  }

  Future<String> insertMealPlan(MealPlan plan, String userId) async {
    final id = plan.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;

    final mealPlanMap = plan.toMap();
    mealPlanMap[columnId] = id;
    mealPlanMap[columnUserId] = userId;
    mealPlanMap[columnCreatedAt] = now;
    mealPlanMap[columnUpdatedAt] = now;
    mealPlanMap[columnLastModified] = now;

    try {
      await executeWithRecovery((db) async {
        final dbHash = db.hashCode;
        final dbPath = db.path;
        print('[DIAG] About to execute insert operation on DB hash: $dbHash');
        print('[DIAG] DB path: $dbPath');
        
        await db.insert(
          tableName,
          mealPlanMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        print('[DIAG] Insert operation completed successfully on DB hash: $dbHash');
        return true;
      });
      
      print('MealPlanDB: Successfully inserted meal plan with ID: $id');
      return id;
    } on Exception catch (e) {
      print('MealPlanDB: Error inserting meal plan: $e');
      rethrow;
    }
  }

  Future<bool> updateMealPlan(MealPlan plan) async {
    if (plan.id == null) {
      throw ArgumentError('Cannot update a meal plan without an ID');
    }

    final existingPlan = await getMealPlanById(plan.id!);
    if (existingPlan == null) {
      print('MealPlanDB: Meal plan ${plan.id} not found for update.');
      return false;
    }

    final existingLastModified =
        existingPlan.lastModified?.millisecondsSinceEpoch ?? 0;
    final newLastModified = DateTime.now().millisecondsSinceEpoch;

    // If the existing plan has a newer lastModified timestamp, don't update
    if (plan.lastModified != null &&
        existingLastModified > plan.lastModified!.millisecondsSinceEpoch) {
      print(
        'MealPlanDB: Skipping update for meal plan ${plan.id} due to conflict resolution.',
      );
      return false;
    }

    final mealPlanMap = plan.toMap();
    mealPlanMap[columnUpdatedAt] = DateTime.now().millisecondsSinceEpoch;
    mealPlanMap[columnLastModified] = newLastModified;

    // Remove fields that shouldn't be updated
    mealPlanMap.remove(columnId);
    mealPlanMap.remove(columnUserId);
    mealPlanMap.remove(columnCreatedAt);
    mealPlanMap.remove('timestamp');
    mealPlanMap.remove('feedback');

    int rowsAffected = 0;
    try {
      final db = await DatabaseHelper.getInstance();
      final dbHash = db.hashCode;
      final dbPath = db.path;
      print('[DIAG] Starting transaction in updateMealPlan on DB hash: $dbHash');
      print('[DIAG] DB path: $dbPath');
      
      rowsAffected = await executeWithRecovery((db) async {
        print('[DIAG] Updating meal plan on DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');
        
        return await db.update(
          tableName,
          mealPlanMap,
          where: '$columnId = ?',
          whereArgs: [plan.id],
        );
      });
      print('[DIAG] Transaction completed successfully in updateMealPlan on DB hash: $dbHash');
      
      print(
        'MealPlanDB: Updated meal plan ${plan.id}. Rows affected: $rowsAffected',
      );
      return rowsAffected > 0;
    } on Exception catch (e) {
      print('[DIAG] Transaction failed in updateMealPlan on DB hash: ${await DatabaseHelper.getInstance().hashCode} with error: $e');
      print('MealPlanDB: Error updating meal plan: $e');
      rethrow;
    }
  }

  Future<List<MealPlan>> getAllPlansForUser(String userId) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final dbHash = db.hashCode;
      final dbPath = db.path;
      print('[DIAG] getAllPlansForUser starting with DB hash: $dbHash');
      print('[DIAG] DB path: $dbPath');
      
      final List<Map<String, dynamic>> maps = await executeWithRecovery((db) async {
        print('[DIAG] Getting all plans for user on DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');
        
        return await db.query(
          tableName,
          where: '$columnUserId = ?',
          whereArgs: [userId],
          orderBy: '$columnCreatedAt DESC',
        );
      });
      print('[DIAG] Query completed successfully in getAllPlansForUser on DB hash: $dbHash');
      
      if (maps.isEmpty) return [];

      return List.generate(maps.length, (i) {
        return MealPlan.fromMap(maps[i]);
      });
    } on Exception catch (e) {
      print('MealPlanDB: Error getting all plans for user: $e');
      rethrow;
    }
  }

  Future<List<MealPlan>> getAllPlans({String? userId}) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final dbHash = db.hashCode;
      final dbPath = db.path;
      print('[DIAG] getAllPlans starting with DB hash: $dbHash');
      print('[DIAG] DB path: $dbPath');
      
      final List<Map<String, dynamic>> maps = await executeWithRecovery((db) async {
        print('[DIAG] Getting all plans on DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');
        
        return await db.query(
          tableName,
          where: userId != null ? '$columnUserId = ?' : null,
          whereArgs: userId != null ? [userId] : null,
          orderBy: '$columnCreatedAt DESC',
        );
      });
      print('[DIAG] Query completed successfully in getAllPlans on DB hash: $dbHash');

      if (maps.isEmpty) return [];

      return List.generate(maps.length, (i) {
        return MealPlan.fromMap(maps[i]);
      });
    } on Exception catch (e) {
      print('MealPlanDB: Error getting all plans: $e');
      rethrow;
    }
  }

  Future<MealPlan?> getMealPlanById(String id) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final dbHash = db.hashCode;
      final dbPath = db.path;
      print('[DIAG] getMealPlanById starting with DB hash: $dbHash');
      print('[DIAG] DB path: $dbPath');
      
      final List<Map<String, dynamic>> maps = await executeWithRecovery((db) async {
        print('[DIAG] Getting meal plan by ID on DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');
        
        return await db.query(
          tableName,
          where: '$columnId = ?',
          whereArgs: [id],
        );
      });
      print('[DIAG] Query completed successfully in getMealPlanById on DB hash: $dbHash');

      if (maps.isNotEmpty) {
        return MealPlan.fromMap(maps.first);
      }
      return null;
    } on Exception catch (e) {
      print('MealPlanDB: Error getting meal plan by ID: $e');
      rethrow;
    }
  }

  Future<int> deleteMealPlan(String id) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final dbHash = db.hashCode;
      final dbPath = db.path;
      print('[DIAG] deleteMealPlan starting with DB hash: $dbHash');
      print('[DIAG] DB path: $dbPath');
      
      print('[DIAG] Starting transaction in deleteMealPlan on DB hash: $dbHash');
      final rowsDeleted = await executeWithRecovery((db) async {
        print('[DIAG] Deleting meal plan on DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');
        
        return await db.delete(
          tableName,
          where: '$columnId = ?',
          whereArgs: [id],
        );
      });
      print('[DIAG] Delete operation completed successfully in deleteMealPlan on DB hash: $dbHash');
      
      return rowsDeleted;
    } on Exception catch (e) {
      print('MealPlanDB: Error deleting meal plan: $e');
      rethrow;
    }
  }
}