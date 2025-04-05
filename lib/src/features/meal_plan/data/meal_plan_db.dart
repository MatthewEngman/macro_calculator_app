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
        timestamp TEXT NOT NULL
      )
    ''');
  }

  static Future<int> insertMealPlan(MealPlan plan) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, plan.toMap());
  }

  static Future<List<MealPlan>> getAllPlans() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => MealPlan.fromMap(maps[i]));
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
    return MealPlan.fromMap(maps.first);
  }

  static Future<int> updateFeedback(int id, String feedback) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      {'feedback': feedback},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteMealPlan(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
