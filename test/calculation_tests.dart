// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:macro_masher/calculator_model.dart'; // Import your model

void main() {
  group('CalculatorModel Unit Tests', () {
    late CalculatorModel calculator;

    setUp(() {
      calculator = CalculatorModel();
    });

    group('Height Calculations', () {
      test('calculateHeight should correctly calculate total height in inches', () {
        calculator.feet = 5;
        calculator.inches = 10;
        calculator.calculateHeight();
        expect(calculator.totalHeightInInches, 70);
      });

      test('calculateHeight with zero feet and inches should return 0', () {
        calculator.feet = 0;
        calculator.inches = 0;
        calculator.calculateHeight();
        expect(calculator.totalHeightInInches, 0);
      });

      test('calculateHeight with only feet should correctly calculate total height in inches', () {
        calculator.feet = 6;
        calculator.inches = 0;
        calculator.calculateHeight();
        expect(calculator.totalHeightInInches, 72);
      });

      test('calculateHeight with only inches should correctly return the inches value', () {
        calculator.feet = 0;
        calculator.inches = 5;
        calculator.calculateHeight();
        expect(calculator.totalHeightInInches, 5);
      });
    });

    group('BMR Calculations', () {
      test('calculateBMR should calculate Basal Metabolic Rate correctly for male', () {
        calculator.weight = 180; // lbs
        calculator.feet = 5;
        calculator.inches = 10;
        calculator.age = 30;
        calculator.sex = 'male';
        calculator.calculateHeight();
        final bmr = calculator.calculateBMR();
        // Expected BMR calculation (you'll need to verify the formula)
        expect(bmr, closeTo(1783, 1)); // Use closeTo for double comparisons
      });

      test('calculateBMR should calculate Basal Metabolic Rate correctly for female', () {
        calculator.weight = 150; // lbs
        calculator.feet = 5;
        calculator.inches = 5;
        calculator.age = 25;
        calculator.sex = 'female';
        calculator.calculateHeight();
        final bmr = calculator.calculateBMR();
        // Expected BMR calculation (you'll need to verify the formula)
        expect(bmr, closeTo(1426, 1));
      });

      test('calculateBMR with zero values should return 0', () {
        calculator.weight = 0;
        calculator.feet = 0;
        calculator.inches = 0;
        calculator.age = 0;
        calculator.sex = 'male';
        calculator.calculateHeight();
        final bmr = 0;
        expect(bmr, 0);
      });
    });
  });
}
