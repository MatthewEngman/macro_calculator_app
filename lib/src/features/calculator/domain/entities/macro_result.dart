class MacroResult {
  final String? id;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? calculationType;
  final DateTime? timestamp;
  final bool isDefault;
  final String? name;
  final DateTime? lastModified;

  MacroResult({
    this.id,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calculationType,
    this.timestamp,
    this.isDefault = false,
    this.name,
    this.lastModified,
  });

  MacroResult copyWith({
    String? id,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? calculationType,
    DateTime? timestamp,
    bool? isDefault,
    String? name,
    DateTime? lastModified,
  }) {
    return MacroResult(
      id: id ?? this.id,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calculationType: calculationType ?? this.calculationType,
      timestamp: timestamp ?? this.timestamp,
      isDefault: isDefault ?? this.isDefault,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
