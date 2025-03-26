import 'package:flutter/material.dart';

class CalculatorModel extends ChangeNotifier {
  // Input Fields
  double weight = 0.0;
  double height = 0.0;
  int feet = 0;
  int inches = 0;
  int age = 0;
  String sex = 'male'; // Default value
  String activityLevel = 'sedentary'; //Default Value
  String _goal = 'maintain';
  double weightChangeRate = 0.0; // lbs per week

  String get goal => _goal;
  set goal(String value) {
    _goal = value;
    notifyListeners();
  }

  // Calculated Results
  double calories = 0.0;
  double protein = 0.0;
  double carbs = 0.0;
  double fat = 0.0;
  double totalHeightInInches = 0.0;

  void setFeet(int newFeet) {
    feet = newFeet;
    calculateHeight();
    notifyListeners();
  }

  void setInches(int newInches) {
    inches = newInches;
    calculateHeight();
    notifyListeners();
  }

  void calculateHeight() {
    if (feet < 0 || inches < 0) {
      totalHeightInInches = 0.0; // Reset if invalid
    } else {
      totalHeightInInches = (feet * 12.0) + inches;
    }
  }

  double calculateBMR() {
    return _calculateBMR(sex, weight, totalHeightInInches, age);
  }

  double _calculateBMR(String sex, double weight, double totalHeightInInches, int age) {
    if (sex == 'male') {
      return (10 * (weight * 0.453592)) + (6.25 * (totalHeightInInches * 2.54)) -
          (5 * age) + 5;
    } else {
      return (10 * (weight * 0.453592)) + (6.25 * (totalHeightInInches * 2.54)) -
          (5 * age) - 161;
    }
  }

     double _calculateTDEE(double bmr) {
       double activityMultiplier;
       switch (activityLevel) {
         case 'sedentary':
           activityMultiplier = 1.2;
           break;
         case 'lightly active':
           activityMultiplier = 1.375;
           break;
         case 'moderately active':
           activityMultiplier = 1.55;
           break;
         case 'very active':
           activityMultiplier = 1.725;
           break;
         case 'extra active':
           activityMultiplier = 1.9;
           break;
         default:
           activityMultiplier = 1.2; // Default to sedentary
       }
       return bmr * activityMultiplier;
     }

     void calculateMacros() {
       double bmr = calculateBMR();
       double tdee = _calculateTDEE(bmr);

       // 1. Adjust target calories based on the goal
       if (_goal == 'lose') {
         calories = tdee - (weightChangeRate * 500); // Subtract calories for weight loss
       } else if (_goal == 'gain') {
         calories = tdee + (weightChangeRate * 500); // Add calories for weight gain
       } else {
         calories = tdee; // Maintain: calories equal TDEE
       }

       // 2. Calculate macros based on the final adjusted 'calories' value
       // These calculations now happen for ALL goals (lose, maintain, gain)
       protein = (calories * 0.30) / 4; // 30% protein, 4 kcal/gram
       carbs = (calories * 0.40) / 4;   // 40% carbs, 4 kcal/gram
       fat = (calories * 0.30) / 9;     // 30% fat, 9 kcal/gram

       // 3. Notify listeners to update the UI
       notifyListeners();
     }
  }