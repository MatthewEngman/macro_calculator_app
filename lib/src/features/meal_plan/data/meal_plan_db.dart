import 'package:sqflite/sqflite.dart';
import '../../../core/persistence/database_helper.dart';
import '../models/meal_plan.dart';

class MealPlanDB {
  static const String tableName = 'meal_plans';

  static Database? _db;

  static void setDatabase(Database db) {
    _db = db;
    print('MealPlanDB: Database instance set manually');
  }

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

  static Future<void> createTable(Database db) async {
    await db.execute('''
          CREATE TABLE $tableName (
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
  }

  static Future<String> insertMealPlan(MealPlan plan, String userId) async {
    final db = _db ?? await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final mealPlanMap = plan.toMap();

    mealPlanMap[columnId] = plan.id;
    mealPlanMap[columnUserId] = userId;
    mealPlanMap[columnCreatedAt] = now;
    mealPlanMap[columnUpdatedAt] = now;
    mealPlanMap[columnLastModified] = now;
    mealPlanMap.remove('timestamp');
    mealPlanMap.remove('feedback');

    await db.insert(
      tableName,
      mealPlanMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('MealPlanDB: Inserted meal plan ${plan.id} for user $userId');
    // Assert that plan.id is not null, as the method must return a non-null String.
    // This implies that the ID must be generated before calling insertMealPlan.
    return plan.id!;
  }

  static Future<bool> updateMealPlan(MealPlan plan) async {
    final db = _db ?? await DatabaseHelper.instance.database;

    if (plan.id == null) {
      throw ArgumentError('Cannot update a meal plan without an ID');
    }

    // Assert non-null when passing plan.id to getMealPlanById
    final existingPlan = await getMealPlanById(plan.id!);
    if (existingPlan == null) {
      print('MealPlanDB: Meal plan ${plan.id} not found for update.');
      return false;
    }

    final existingLastModified =
        existingPlan.lastModified?.millisecondsSinceEpoch ?? 0;
    final newLastModified = DateTime.now().millisecondsSinceEpoch;

    if (existingLastModified > newLastModified) {
      print(
        'MealPlanDB: Existing meal plan ${plan.id} is newer. Skipping update.',
      );
      return false;
    }

    final mealPlanMap = plan.toMap();

    mealPlanMap[columnUpdatedAt] = newLastModified;
    mealPlanMap[columnLastModified] = newLastModified;
    mealPlanMap.remove(columnId);
    mealPlanMap.remove(columnUserId);
    mealPlanMap.remove(columnCreatedAt);
    mealPlanMap.remove('timestamp');
    mealPlanMap.remove('feedback');

    final rowsAffected = await db.update(
      tableName,
      mealPlanMap,
      where: '$columnId = ?',
      whereArgs: [plan.id],
    );
    print(
      'MealPlanDB: Updated meal plan ${plan.id}. Rows affected: $rowsAffected',
    );
    return rowsAffected > 0;
  }

  static Future<List<MealPlan>> getAllPlansForUser(String userId) async {
    final db = _db ?? await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnUserId = ?',
      whereArgs: [userId],
      orderBy: '$columnCreatedAt DESC',
    );

    if (maps.isEmpty) return [];

    return List.generate(maps.length, (i) {
      return MealPlan.fromMap(maps[i]);
    });
  }

  /// Gets ALL meal plans from the database (used for syncing)
  static Future<List<MealPlan>> getAllPlans() async {
    final db = _db ?? await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: '$columnCreatedAt DESC',
    );

    if (maps.isEmpty) return [];

    return List.generate(maps.length, (i) {
      return MealPlan.fromMap(maps[i]);
    });
  }

  static Future<MealPlan?> getMealPlanById(String id) async {
    final db = _db ?? await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return MealPlan.fromMap(maps.first);
  }

  static Future<int> deleteMealPlan(String id) async {
    final db = _db ?? await DatabaseHelper.instance.database;
    print('MealPlanDB: Deleting meal plan $id');
    return await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }
}
