import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macro_masher/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:macro_masher/src/features/calculator/presentation/widgets/input_field.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap calculate button and verify results', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Fill in weight
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '180',
      );
      await tester.pumpAndSettle();

      // Fill in height (feet and inches for imperial)
      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '5');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '10');
      await tester.pumpAndSettle();

      // Fill in age
      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '30',
      );
      await tester.pumpAndSettle();

      // Find and tap calculate button
      final calculateButton = find.widgetWithIcon(
        FilledButton,
        Icons.calculate,
      );
      expect(calculateButton, findsOneWidget);
      await tester.tap(calculateButton);
      await tester.pumpAndSettle();

      // Verify results are shown
      expect(find.text('Macro Results'), findsOneWidget);
      expect(find.textContaining('Calories:'), findsOneWidget);
      expect(find.textContaining('Protein:'), findsOneWidget);
      expect(find.textContaining('Carbs:'), findsOneWidget);
      expect(find.textContaining('Fat:'), findsOneWidget);
    });

    testWidgets('verify input validation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test invalid weight
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '-1',
      );
      await tester.pumpAndSettle();
      expect(find.text('Weight must be greater than 0'), findsOneWidget);

      // Test invalid height (feet)
      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '3');
      await tester.pumpAndSettle();
      expect(find.text('Enter 4-7'), findsOneWidget);

      // Test invalid height (inches)
      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '12');
      await tester.pumpAndSettle();
      expect(find.text('Enter 0-11'), findsOneWidget);

      // Test invalid age
      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '0',
      );
      await tester.pumpAndSettle();
      expect(find.text('Age must be greater than 0'), findsOneWidget);
    });

    testWidgets('verify unit conversion', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap unit toggle
      final unitToggle = find.widgetWithIcon(FilledButton, Icons.swap_horiz);
      expect(unitToggle, findsOneWidget);
      await tester.tap(unitToggle);
      await tester.pumpAndSettle();

      // Verify unit labels changed
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);

      // Enter metric values
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (kg):'),
        '82',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(InputField, 'Height (cm):'),
        '180',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '30',
      );
      await tester.pumpAndSettle();

      // Calculate and verify results
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      expect(find.text('Macro Results'), findsOneWidget);
      expect(find.textContaining('Calories:'), findsOneWidget);
    });

    testWidgets('verify goal selection changes macros', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter base values
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '180',
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '5');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '10');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '30',
      );
      await tester.pumpAndSettle();

      // Calculate maintenance calories
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      final maintenanceCalories = _extractCalories(find);

      // Change goal to weight loss
      await tester.tap(find.widgetWithText(DropdownButton, 'Maintenance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weight Loss').last);
      await tester.pumpAndSettle();

      // Calculate weight loss calories
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      final weightLossCalories = _extractCalories(find);
      expect(weightLossCalories, lessThan(maintenanceCalories));
    });

    testWidgets('verify form validation and calculation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to calculate with empty fields
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your weight'), findsOneWidget);
      expect(find.text('Please enter your height'), findsOneWidget);
      expect(find.text('Please enter your age'), findsOneWidget);

      // Enter invalid values
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '1000',
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '3');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '12');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '150',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      // Verify error messages for invalid values
      expect(
        find.text('Weight must be between 66.0 and 660.0 lbs'),
        findsOneWidget,
      );
      expect(find.text('Enter 4-7'), findsOneWidget);
      expect(find.text('Enter 0-11'), findsOneWidget);
      expect(find.text('Age must be between 18 and 120'), findsOneWidget);

      // Enter valid values
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '180',
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '5');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '10');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '30',
      );
      await tester.pumpAndSettle();

      // Calculate with valid values
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      // Verify calculation results
      expect(find.text('Macro Results'), findsOneWidget);
      expect(find.textContaining('Calories:'), findsOneWidget);
      expect(find.textContaining('Protein:'), findsOneWidget);
      expect(find.textContaining('Carbs:'), findsOneWidget);
      expect(find.textContaining('Fat:'), findsOneWidget);
    });

    testWidgets('verify unit conversion preserves values', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter imperial values
      await tester.enterText(
        find.widgetWithText(InputField, 'Weight (lbs):'),
        '180',
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Feet:'), '5');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(InputField, 'Inches:'), '10');
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();

      // Switch to metric
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.swap_horiz));
      await tester.pumpAndSettle();

      // Calculate in metric
      await tester.enterText(
        find.widgetWithText(InputField, 'Age (years):'),
        '30',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      // Get metric results
      final metricCalories = _extractCalories(find);

      // Switch back to imperial
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.swap_horiz));
      await tester.pumpAndSettle();

      // Calculate in imperial
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.calculate));
      await tester.pumpAndSettle();

      // Verify calories are the same (within rounding)
      final imperialCalories = _extractCalories(find);
      expect(
        (metricCalories - imperialCalories).abs() < 10,
        isTrue,
        reason: 'Calorie difference should be minimal after unit conversion',
      );
    });
  });
}

int _extractCalories(CommonFinders find) {
  final caloriesText =
      find.textContaining('Calories:').evaluate().single.widget as Text;
  final caloriesString = caloriesText.data!.replaceAll(RegExp(r'[^0-9]'), '');
  return int.parse(caloriesString);
}
