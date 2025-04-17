import 'dart:convert';

import '../data/meal_plan_db.dart'; // Import for column names

class MealPlan {
  final String? id; // Changed to String?
  final String userId; // Added
  final String? date; // Added (Date plan is for)
  final String? meals; // Added (JSON String of meal details)
  final double? totalCalories; // Added
  final double? totalProtein; // Added
  final double? totalCarbs; // Added
  final double? totalFat; // Added
  final String? notes; // Added
  final String? firebaseUserId; // Added
  final DateTime? createdAt; // Added
  final DateTime? updatedAt; // Added
  final DateTime? lastModified; // Keep

  // Removed old fields: diet, goal, macros, ingredients, plan, feedback, timestamp

  MealPlan({
    this.id,
    required this.userId,
    this.date,
    this.meals,
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.notes,
    this.firebaseUserId,
    this.createdAt,
    this.updatedAt,
    this.lastModified,
  });

  Map<String, dynamic> toMap() {
    // Use MealPlanDB column constants
    return {
      MealPlanDB.columnId: id,
      MealPlanDB.columnUserId: userId,
      MealPlanDB.columnDate: date,
      MealPlanDB.columnMeals:
          meals, // Assume meals is already a JSON string if needed
      MealPlanDB.columnTotalCalories: totalCalories,
      MealPlanDB.columnTotalProtein: totalProtein,
      MealPlanDB.columnTotalCarbs: totalCarbs,
      MealPlanDB.columnTotalFat: totalFat,
      MealPlanDB.columnNotes: notes,
      MealPlanDB.columnFirebaseUserId: firebaseUserId,
      MealPlanDB.columnCreatedAt: createdAt?.millisecondsSinceEpoch,
      MealPlanDB.columnUpdatedAt: updatedAt?.millisecondsSinceEpoch,
      MealPlanDB.columnLastModified: lastModified?.millisecondsSinceEpoch,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    // Use MealPlanDB column constants
    return MealPlan(
      id: map[MealPlanDB.columnId] as String?,
      userId: map[MealPlanDB.columnUserId] as String,
      date: map[MealPlanDB.columnDate] as String?,
      meals:
          map[MealPlanDB.columnMeals]
              as String?, // Assume meals is stored as JSON string
      totalCalories: map[MealPlanDB.columnTotalCalories] as double?,
      totalProtein: map[MealPlanDB.columnTotalProtein] as double?,
      totalCarbs: map[MealPlanDB.columnTotalCarbs] as double?,
      totalFat: map[MealPlanDB.columnTotalFat] as double?,
      notes: map[MealPlanDB.columnNotes] as String?,
      firebaseUserId: map[MealPlanDB.columnFirebaseUserId] as String?,
      createdAt:
          map[MealPlanDB.columnCreatedAt] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map[MealPlanDB.columnCreatedAt] as int,
              )
              : null,
      updatedAt:
          map[MealPlanDB.columnUpdatedAt] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map[MealPlanDB.columnUpdatedAt] as int,
              )
              : null,
      lastModified:
          map[MealPlanDB.columnLastModified] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map[MealPlanDB.columnLastModified] as int,
              )
              : null,
    );
  }

  MealPlan copyWith({
    String? id,
    String? userId,
    String? date,
    String? meals,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    String? notes,
    String? firebaseUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      notes: notes ?? this.notes,
      firebaseUserId: firebaseUserId ?? this.firebaseUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, userId: $userId, date: $date, meals: $meals, totalCalories: $totalCalories, totalProtein: $totalProtein, totalCarbs: $totalCarbs, totalFat: $totalFat, notes: $notes, firebaseUserId: $firebaseUserId, createdAt: $createdAt, updatedAt: $updatedAt, lastModified: $lastModified)';
  }
}
