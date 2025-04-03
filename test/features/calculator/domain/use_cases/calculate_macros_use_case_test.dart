import 'package:macro_masher/src/features/calculator/domain/entities/calculation_input.dart';
import 'package:macro_masher/src/features/calculator/domain/use_cases/calculate_macros_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculateMacrosUseCase calculateMacrosUseCase;

  setUp(() {
    calculateMacrosUseCase = CalculateMacrosUseCase();
  });

  group('CalculateMacrosUseCase', () {
    test('should calculate correct macros for maintenance', () {
      final input = CalculationInput(
        weight: 180,
        feet: 5,
        inches: 10,
        age: 30,
        sex: 'male',
        activityLevel: 'moderatelyActive',
        goal: 'maintain',
      );

      final result = calculateMacrosUseCase.execute(input);

      expect(result, isNotNull);
      expect(result.calories, greaterThan(0));
      expect(result.protein, greaterThan(0));
      expect(result.carbs, greaterThan(0));
      expect(result.fat, greaterThan(0));
    });
  });
}
