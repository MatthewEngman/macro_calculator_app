class MealPlan {
  int? id;
  String diet;
  String goal;
  Map<String, dynamic> macros;
  List<String> ingredients;
  String plan;
  String feedback;
  DateTime timestamp;

  MealPlan({
    this.id,
    required this.diet,
    required this.goal,
    required this.macros,
    required this.ingredients,
    required this.plan,
    this.feedback = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diet': diet,
      'goal': goal,
      'macros': macros.toString(),
      'ingredients': ingredients.join(','),
      'plan': plan,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      diet: map['diet'],
      goal: map['goal'],
      macros: Map<String, dynamic>.from(eval(map['macros'])),
      ingredients: map['ingredients'].split(','),
      plan: map['plan'],
      feedback: map['feedback'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
