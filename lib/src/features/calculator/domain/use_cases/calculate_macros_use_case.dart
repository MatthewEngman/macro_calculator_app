import '../entities/calculation_input.dart';
import '../entities/macro_result.dart';

class CalculateMacrosUseCase {
  //Moved the logic from the old model to a use case
  MacroResult execute(CalculationInput input) {
    // Perform the macro calculations here based on the input
    double bmr;
    if (input.sex == 'male') {
      bmr = 66 + (6.23 * input.weight) + (12.7 * ((input.feet * 12) + input.inches)) - (6.8 * input.age);
    } else {
      bmr = 655 + (4.35 * input.weight) + (4.7 * ((input.feet * 12) + input.inches)) - (4.7 * input.age);
    }

    double activityFactor = _getActivityFactor(input.activityLevel);
    double maintenanceCalories = bmr * activityFactor;

    double targetCalories = _getTargetCalories(maintenanceCalories, input.goal, input.weightChangeRate ?? 0);
    double protein = input.weight * 1;
    double fat = targetCalories * 0.25 / 9;
    double carbs = (targetCalories - (protein * 4) - (fat * 9)) / 4;

    return MacroResult(
      calories: targetCalories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  double _getActivityFactor(String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2;
      case 'lightly active':
        return 1.375;
      case 'moderately active':
        return 1.55;
      case 'very active':
        return 1.725;
      case 'extra active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  double _getTargetCalories(double maintenanceCalories, String goal, double weightChangeRate) {
    switch (goal) {
      case 'lose':
        return maintenanceCalories - (weightChangeRate * 500);
      case 'gain':
        return maintenanceCalories + (weightChangeRate * 500);
      default:
        return maintenanceCalories;
    }
  }
}
