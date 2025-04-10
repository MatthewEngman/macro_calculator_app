class MacroResult {
  final String? id;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? timestamp;
  final bool isDefault;

  MacroResult({
    this.id,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.timestamp,
    this.isDefault = false,
  });

  MacroResult copyWith({
    String? id,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? timestamp,
    bool? isDefault,
  }) {
    return MacroResult(
      id: id ?? this.id,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
