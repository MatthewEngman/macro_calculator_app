class MacroResult {
  final String? id;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? calculationType; // Add this field
  final DateTime? timestamp;
  final bool isDefault;
  final String? name; // Add this field

  MacroResult({
    this.id,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calculationType, // Add this parameter
    this.timestamp,
    this.isDefault = false,
    this.name, // Add this parameter
  });

  // Update copyWith method as well
  MacroResult copyWith({
    String? id,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? calculationType, // Add this parameter
    DateTime? timestamp,
    bool? isDefault,
    String? name, // Add this parameter
  }) {
    return MacroResult(
      id: id ?? this.id,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calculationType: calculationType ?? this.calculationType, // Add this
      timestamp: timestamp ?? this.timestamp,
      isDefault: isDefault ?? this.isDefault,
      name: name ?? this.name, // Add this
    );
  }
}
