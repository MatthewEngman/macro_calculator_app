import 'package:sqflite/sqflite.dart';
import '../models/meal_plan.dart';

class MealPlanDB {
  final Database database;

  MealPlanDB({required this.database});

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

  static Future<void> createTable(Database db) async {
    try {
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
    mealPlanMap.remove('timestamp');
    mealPlanMap.remove('feedback');

    await database.insert(
      tableName,
      mealPlanMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('MealPlanDB: Inserted meal plan $id for user $userId');
    return id;
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

    int rowsAffected = 0;
    await database.transaction((txn) async {
      rowsAffected = await txn.update(
        tableName,
        mealPlanMap,
        where: '$columnId = ?',
        whereArgs: [plan.id],
      );
    });

    print(
      'MealPlanDB: Updated meal plan ${plan.id}. Rows affected: $rowsAffected',
    );
    return rowsAffected > 0;
  }

  // Fetch all meal plans for a specific user
  Future<List<MealPlan>> getAllPlans({required String userId}) async {
    try {
      print('MealPlanDB: getAllPlans called for userId: $userId');
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: '$columnUserId = ?', // Filter by userId
        whereArgs: [userId],
      );
      print('MealPlanDB: Found ${maps.length} plans for userId $userId');
      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) {
          return MealPlan.fromMap(maps[i]);
        });
      } else {
        return [];
      }
    } catch (e) {
      print('MealPlanDB: Error fetching all plans for user $userId: $e');
      return [];
    }
  }

  Future<List<MealPlan>> getAllPlansForUser(String userId) async {
    final List<Map<String, dynamic>> maps = await database.query(
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

  Future<MealPlan?> getMealPlanById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return MealPlan.fromMap(maps.first);
  }

  Future<int> deleteMealPlan(String id) async {
    print('MealPlanDB: Deleting meal plan $id');
    return await database.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }
}
