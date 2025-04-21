import 'dart:convert';
import 'package:http/http.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/persistence/database_helper.dart';

class MealLog {
  final String? id;
  final String? userId;
  final DateTime date;
  final String mealType;
  final List<FoodItem> foodItems;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? firebaseUserId;

  MealLog({
    this.id,
    this.userId,
    required this.date,
    required this.mealType,
    required this.foodItems,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.firebaseUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'mealType': mealType,
      'foodItems': jsonEncode(foodItems.map((item) => item.toMap()).toList()),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'firebaseUserId': firebaseUserId,
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map) {
    final foodItemsJson = jsonDecode(map['foodItems'] as String) as List;
    return MealLog(
      id: map['id'] as String?,
      userId: map['userId'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      mealType: map['mealType'] as String,
      foodItems:
          foodItemsJson
              .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
              .toList(),
      calories: map['calories'] as int,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      firebaseUserId: map['firebaseUserId'] as String?,
    );
  }
}

class FoodItem {
  final String name;
  final int quantity;
  final String unit;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      unit: map['unit'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
    );
  }
}

class MealLogDB {
  static const String tableName = 'meal_logs';

  // Column names
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnDate = 'date';
  static const String columnMealType = 'meal_type';
  static const String columnFoodItems = 'food_items';
  static const String columnCalories = 'calories';
  static const String columnProtein = 'protein';
  static const String columnCarbs = 'carbs';
  static const String columnFat = 'fat';
  static const String columnFirebaseUserId = 'firebase_user_id';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnUserId TEXT,
        $columnDate INTEGER NOT NULL,
        $columnMealType TEXT NOT NULL,
        $columnFoodItems TEXT NOT NULL,
        $columnCalories INTEGER NOT NULL,
        $columnProtein REAL NOT NULL,
        $columnCarbs REAL NOT NULL,
        $columnFat REAL NOT NULL,
        $columnFirebaseUserId TEXT,
        FOREIGN KEY($columnUserId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<String> insertMealLog(MealLog mealLog) async {
    final db = await DatabaseHelper.database;

    final id = mealLog.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final Map<String, dynamic> row = {
      columnId: id,
      columnUserId: mealLog.userId,
      columnDate: mealLog.date.millisecondsSinceEpoch,
      columnMealType: mealLog.mealType,
      columnFoodItems: jsonEncode(
        mealLog.foodItems.map((item) => item.toMap()).toList(),
      ),
      columnCalories: mealLog.calories,
      columnProtein: mealLog.protein,
      columnCarbs: mealLog.carbs,
      columnFat: mealLog.fat,
      columnFirebaseUserId: mealLog.firebaseUserId,
    };

    await db.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  static Future<List<MealLog>> getMealLogsForDay(
    DateTime date, {
    String? userId,
    String? firebaseUserId,
  }) async {
    final db = await DatabaseHelper.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ? AND $columnUserId = ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
          userId,
        ],
        orderBy: '$columnDate ASC',
      );
    } else if (firebaseUserId != null) {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ? AND $columnFirebaseUserId = ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
          firebaseUserId,
        ],
        orderBy: '$columnDate ASC',
      );
    } else {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
        orderBy: '$columnDate ASC',
      );
    }

    return List.generate(maps.length, (i) {
      final foodItemsJson =
          jsonDecode(maps[i][columnFoodItems] as String) as List;
      return MealLog(
        id: maps[i][columnId],
        userId: maps[i][columnUserId],
        date: DateTime.fromMillisecondsSinceEpoch(maps[i][columnDate]),
        mealType: maps[i][columnMealType],
        foodItems:
            foodItemsJson
                .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
                .toList(),
        calories: maps[i][columnCalories],
        protein: maps[i][columnProtein],
        carbs: maps[i][columnCarbs],
        fat: maps[i][columnFat],
        firebaseUserId: maps[i][columnFirebaseUserId],
      );
    });
  }

  static Future<List<MealLog>> getMealLogsForDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
    String? firebaseUserId,
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

    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ? AND $columnUserId = ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
          userId,
        ],
        orderBy: '$columnDate ASC',
      );
    } else if (firebaseUserId != null) {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ? AND $columnFirebaseUserId = ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
          firebaseUserId,
        ],
        orderBy: '$columnDate ASC',
      );
    } else {
      maps = await db.query(
        tableName,
        where: '$columnDate BETWEEN ? AND ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
        orderBy: '$columnDate ASC',
      );
    }

    return List.generate(maps.length, (i) {
      final foodItemsJson =
          jsonDecode(maps[i][columnFoodItems] as String) as List;
      return MealLog(
        id: maps[i][columnId],
        userId: maps[i][columnUserId],
        date: DateTime.fromMillisecondsSinceEpoch(maps[i][columnDate]),
        mealType: maps[i][columnMealType],
        foodItems:
            foodItemsJson
                .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
                .toList(),
        calories: maps[i][columnCalories],
        protein: maps[i][columnProtein],
        carbs: maps[i][columnCarbs],
        fat: maps[i][columnFat],
        firebaseUserId: maps[i][columnFirebaseUserId],
      );
    });
  }

  static Future<int> deleteMealLog(String id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }
}
