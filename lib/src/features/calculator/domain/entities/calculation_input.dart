class CalculationInput {
  final double weight;
  final int feet;
  final int inches;
  final int age;
  final String sex;
  final String activityLevel;
  final String goal;
  final double? weightChangeRate;

  CalculationInput({
    required this.weight,
    required this.feet,
    required this.inches,
    required this.age,
    required this.sex,
    required this.activityLevel,
    required this.goal,
    this.weightChangeRate,
  });
}