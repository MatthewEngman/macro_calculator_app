import 'package:flutter_test/flutter_test.dart';
import 'package:macro_masher/src/features/calculator/domain/entities/macro_result.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';

void main() {
  group('MacroResult.fromUserInfo', () {
    test('calculates macros for male, imperial, lose', () {
      final user = UserInfo(
        id: '1',
        weight: 180, // lbs
        feet: 5,
        inches: 10,
        age: 30,
        sex: 'male',
        activityLevel: ActivityLevel.moderatelyActive,
        goal: Goal.lose,
        units: Units.imperial,
        isDefault: true,
        name: 'Imperial Male Lose',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, inInclusiveRange(1200, 4000));
      expect(result.protein, greaterThan(0));
      expect(result.carbs, greaterThan(0));
      expect(result.fat, greaterThan(0));
    });

    test('calculates macros for female, imperial, gain', () {
      final user = UserInfo(
        id: '2',
        weight: 140, // lbs
        feet: 5,
        inches: 4,
        age: 28,
        sex: 'female',
        activityLevel: ActivityLevel.veryActive,
        goal: Goal.gain,
        units: Units.imperial,
        isDefault: false,
        name: 'Imperial Female Gain',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, inInclusiveRange(1200, 4000));
    });

    test('calculates macros for male, metric, maintain', () {
      final user = UserInfo(
        id: '3',
        weight: 80, // kg
        feet: 1, // meters (if your UI expects this)
        inches: 80, // centimeters (if your UI expects this)
        age: 40,
        sex: 'male',
        activityLevel: ActivityLevel.sedentary,
        goal: Goal.maintain,
        units: Units.metric,
        isDefault: false,
        name: 'Metric Male Maintain',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, inInclusiveRange(1200, 4000));
    });

    test('calculates macros for female, metric, lose', () {
      final user = UserInfo(
        id: '4',
        weight: 60, // kg
        feet: 1,
        inches: 65,
        age: 25,
        sex: 'female',
        activityLevel: ActivityLevel.lightlyActive,
        goal: Goal.lose,
        units: Units.metric,
        isDefault: false,
        name: 'Metric Female Lose',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, inInclusiveRange(1200, 4000));
    });

    test('handles missing/zero input gracefully', () {
      final user = UserInfo(
        id: '5',
        weight: 0,
        feet: 0,
        inches: 0,
        age: 0,
        sex: 'male',
        activityLevel: ActivityLevel.sedentary,
        goal: Goal.maintain,
        units: Units.metric,
        isDefault: false,
        name: 'Zero User',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, 1200); // Should clamp to minimum
    });

    test('clamps calories to max', () {
      final user = UserInfo(
        id: '6',
        weight: 300,
        feet: 7,
        inches: 0,
        age: 25,
        sex: 'male',
        activityLevel: ActivityLevel.extraActive,
        goal: Goal.gain,
        units: Units.imperial,
        isDefault: false,
        name: 'Max User',
        lastModified: DateTime.now(),
      );
      final result = MacroResult.fromUserInfo(user);
      expect(result.calories, 4000); // Should clamp to maximum
    });
  });
}
