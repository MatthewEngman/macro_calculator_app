import 'dart:convert';

class MealPlan {
  final int? id;
  final String diet;
  final String goal;
  final Map<String, int> macros;
  final List<String> ingredients;
  final String plan;
  final String feedback;
  final DateTime timestamp;
  final DateTime? lastModified;

  MealPlan({
    this.id,
    required this.diet,
    required this.goal,
    required this.macros,
    required this.ingredients,
    required this.plan,
    this.feedback = '',
    DateTime? timestamp,
    this.lastModified,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diet': diet,
      'goal': goal,
      'macros': jsonEncode(macros),
      'ingredients': jsonEncode(ingredients),
      'plan': plan,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
      'last_modified': lastModified?.millisecondsSinceEpoch,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'] as int?,
      diet: map['diet'] as String,
      goal: map['goal'] as String,
      macros: Map<String, int>.from(jsonDecode(map['macros'] as String)),
      ingredients: List<String>.from(jsonDecode(map['ingredients'] as String)),
      plan: map['plan'] as String,
      feedback: map['feedback'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      lastModified:
          map['last_modified'] != null
              ? (map['last_modified'] is DateTime
                  ? map['last_modified'] as DateTime
                  : (map['last_modified'] is int
                      ? DateTime.fromMillisecondsSinceEpoch(
                        map['last_modified'] as int,
                      )
                      : DateTime.parse(map['last_modified'] as String)))
              : null,
    );
  }

  MealPlan copyWith({
    int? id,
    String? diet,
    String? goal,
    Map<String, int>? macros,
    List<String>? ingredients,
    String? plan,
    String? feedback,
    DateTime? timestamp,
    DateTime? lastModified,
  }) {
    return MealPlan(
      id: id ?? this.id,
      diet: diet ?? this.diet,
      goal: goal ?? this.goal,
      macros: macros ?? this.macros,
      ingredients: ingredients ?? this.ingredients,
      plan: plan ?? this.plan,
      feedback: feedback ?? this.feedback,
      timestamp: timestamp ?? this.timestamp,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, diet: $diet, goal: $goal, macros: $macros, ingredients: $ingredients, plan: $plan, feedback: $feedback, timestamp: $timestamp, lastModified: $lastModified)';
  }
}
