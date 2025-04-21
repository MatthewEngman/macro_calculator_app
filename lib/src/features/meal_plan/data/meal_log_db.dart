// lib/src/features/meal_plan/data/meal_log_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:macro_masher/src/core/persistence/database_helper.dart';
import 'package:macro_masher/src/features/meal_plan/models/meal_log.dart';

/// Database helper class for MealLog operations
class MealLogDB {
  static const String tableName = 'meal_logs';
  static const String columnMealPlanId = 'meal_plan_id';

  /// Creates the meal_logs table in the database
  static Future<void> createTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          firebase_user_id TEXT NOT NULL,
          meal_name TEXT NOT NULL,
          meal_description TEXT NOT NULL,
          macros TEXT NOT NULL,
          log_date TEXT NOT NULL,
          meal_type TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    } catch (e) {
      // Handle exception
    }
  }

  /// Inserts a new meal log into the database
  static Future<String> insertMealLog(MealLog mealLog) async {
    final db = await DatabaseHelper.database;

    final mealLogData = mealLog.toMap();
    final id = mealLog.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    mealLogData['id'] = id;
    mealLogData['created_at'] = DateTime.now().millisecondsSinceEpoch;

    await db.insert(tableName, mealLogData);
    return id;
  }

  /// Deletes a meal log from the database
  static Future<int> deleteMealLog(String id) async {
    final db = await DatabaseHelper.database;

    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Gets meal logs for a specific day
  static Future<List<MealLog>> getMealLogsForDay(
    DateTime date, {
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'firebase_user_id = ? AND log_date BETWEEN ? AND ?',
      whereArgs: [
        firebaseUserId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'log_date ASC',
    );

    return List.generate(maps.length, (i) {
      return MealLog.fromMap(maps[i]);
    });
  }

  /// Gets meal logs for a date range
  static Future<List<MealLog>> getMealLogsForDateRange(
    DateTime startDate,
    DateTime endDate, {
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.database;

    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'firebase_user_id = ? AND log_date BETWEEN ? AND ?',
      whereArgs: [
        firebaseUserId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'log_date ASC',
    );

    return List.generate(maps.length, (i) {
      return MealLog.fromMap(maps[i]);
    });
  }

  /// Gets all meal logs for a user
  static Future<List<MealLog>> getAllMealLogs({
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'firebase_user_id = ?',
      whereArgs: [firebaseUserId],
      orderBy: 'log_date ASC',
    );

    return List.generate(maps.length, (i) {
      return MealLog.fromMap(maps[i]);
    });
  }

  /// Updates a meal log in the database
  static Future<int> updateMealLog(MealLog mealLog) async {
    final db = await DatabaseHelper.database;

    final mealLogData = mealLog.toMap();

    return await db.update(
      tableName,
      mealLogData,
      where: 'id = ?',
      whereArgs: [mealLog.id],
    );
  }
}
