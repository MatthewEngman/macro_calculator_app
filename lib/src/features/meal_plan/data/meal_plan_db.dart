import 'package:sqflite/sqflite.dart';
import '../../../core/persistence/database_helper.dart';
import '../models/meal_plan.dart';

class MealPlanDB {
  static const String tableName = 'meal_plans';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diet TEXT NOT NULL,
        goal TEXT NOT NULL,
        macros TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        plan TEXT NOT NULL,
        feedback TEXT NOT NULL DEFAULT '',
        timestamp TEXT NOT NULL,
        last_modified INTEGER
      )
    ''');
  }

  static Future<int> insertMealPlan(MealPlan plan) async {
    final db = await DatabaseHelper.instance.database;

    final mealPlanMap = plan.toMap();
    // Add last_modified timestamp if not present
    if (!mealPlanMap.containsKey('last_modified')) {
      mealPlanMap['last_modified'] = DateTime.now().millisecondsSinceEpoch;
    }

    return await db.insert(tableName, mealPlanMap);
  }

  static Future<bool> updateMealPlan(MealPlan plan) async {
    final db = await DatabaseHelper.instance.database;

    if (plan.id == null) {
      throw ArgumentError('Cannot update a meal plan without an ID');
    }

    // First check if the record exists and get its current lastModified value
    final existingPlan = await getMealPlan(plan.id!);
    if (existingPlan == null) {
      // Plan doesn't exist, insert it instead
      await insertMealPlan(plan);
      return true;
    }

    // If the existing record has a newer lastModified timestamp, don't update
    final existingLastModified = existingPlan.lastModified ?? DateTime(1970);
    final newLastModified = plan.lastModified ?? DateTime.now();

    if (existingLastModified.isAfter(newLastModified)) {
      // Existing record is newer, don't update
      return false;
    }

    final mealPlanMap = plan.toMap();
    // Update the last_modified timestamp
    mealPlanMap['last_modified'] = DateTime.now().millisecondsSinceEpoch;

    final rowsAffected = await db.update(
      tableName,
      mealPlanMap,
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    return rowsAffected > 0;
  }

  static Future<List<MealPlan>> getAllPlans() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      // Convert last_modified to DateTime if it exists
      if (map.containsKey('last_modified') && map['last_modified'] != null) {
        map['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
          map['last_modified'],
        );
      }
      return MealPlan.fromMap(map);
    });
  }

  static Future<MealPlan?> getMealPlan(int id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    // Convert last_modified to DateTime if it exists
    if (map.containsKey('last_modified') && map['last_modified'] != null) {
      map['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
        map['last_modified'],
      );
    }

    return MealPlan.fromMap(map);
  }

  static Future<int> updateFeedback(int id, String feedback) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      {
        'feedback': feedback,
        'last_modified': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteMealPlan(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
