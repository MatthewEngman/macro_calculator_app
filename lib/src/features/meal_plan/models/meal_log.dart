// lib/src/features/meal_plan/models/meal_log.dart

import 'dart:convert';

class MealLog {
  final String? id;
  final String? firebaseUserId;
  final String mealName;
  final String mealDescription;
  final Map<String, int> macros;
  final DateTime logDate;
  final String mealType; // breakfast, lunch, dinner, snack

  MealLog({
    this.id,
    this.firebaseUserId,
    required this.mealName,
    required this.mealDescription,
    required this.macros,
    required this.logDate,
    required this.mealType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_user_id': firebaseUserId,
      'meal_name': mealName,
      'meal_description': mealDescription,
      'macros': jsonEncode(macros),
      'log_date': logDate.toIso8601String(),
      'meal_type': mealType,
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'],
      firebaseUserId: map['firebase_user_id'],
      mealName: map['meal_name'],
      mealDescription: map['meal_description'],
      macros: Map<String, int>.from(jsonDecode(map['macros'])),
      logDate: DateTime.parse(map['log_date']),
      mealType: map['meal_type'],
    );
  }

  MealLog copyWith({
    String? id,
    String? firebaseUserId,
    String? mealName,
    String? mealDescription,
    Map<String, int>? macros,
    DateTime? logDate,
    String? mealType,
  }) {
    return MealLog(
      id: id ?? this.id,
      firebaseUserId: firebaseUserId ?? this.firebaseUserId,
      mealName: mealName ?? this.mealName,
      mealDescription: mealDescription ?? this.mealDescription,
      macros: macros ?? this.macros,
      logDate: logDate ?? this.logDate,
      mealType: mealType ?? this.mealType,
    );
  }
}
