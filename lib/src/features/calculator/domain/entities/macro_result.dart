class MacroResult {
  final String? id;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? timestamp;

  MacroResult({
    this.id,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.timestamp,
  });

  MacroResult copyWith({
    String? id,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? timestamp,
  }) {
    return MacroResult(
      id: id ?? this.id,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
