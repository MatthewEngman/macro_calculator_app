import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';

/// Represents the calculated macronutrient results for a user profile.
///
/// This class is typically constructed via [fromUserInfo], which uses the user's
/// profile data (age, sex, height, weight, activity level, and goal) to compute
/// daily calorie and macronutrient recommendations using standard formulas.
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
  final UserInfo? sourceProfile;
  final String? userId;

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
    this.sourceProfile,
    this.userId,
  });

  /// Returns a copy of this [MacroResult] with the given fields replaced.
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
    String? userId,
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
      sourceProfile: this.sourceProfile,
      userId: userId ?? this.userId,
    );
  }

  /// Calculates macronutrient recommendations from a [UserInfo] profile.
  ///
  /// - **Units:**
  ///   - If [userInfo.units] is [Units.imperial], height is calculated from `feet` and `inches` as total inches, then converted to centimeters.
  ///     Weight is assumed to be in pounds and converted to kilograms.
  ///   - If [userInfo.units] is [Units.metric], height is calculated as (`feet` * 100) + `inches`, where `feet` is meters and `inches` is centimeters.
  ///     Weight is assumed to be in kilograms.
  ///
  /// - **Sex:** Accepts 'male' or 'female' for BMR calculation.
  ///
  /// - **ActivityLevel:** Used to determine the activity multiplier for TDEE calculation.
  ///
  /// - **Goal:**
  ///   - [Goal.lose]: Subtracts 500 kcal from maintenance calories.
  ///   - [Goal.gain]: Adds 500 kcal to maintenance calories.
  ///   - [Goal.maintain]: No adjustment.
  ///
  /// - **Clamping:** Calories are clamped between 1200 and 4000 kcal.
  ///
  /// - **Macros:**
  ///   - Protein: 1.8g per kg body weight.
  ///   - Fat: 25% of calories, divided by 9 (kcal/g).
  ///   - Carbs: Remaining calories after protein and fat, divided by 4 (kcal/g).
  ///
  /// - **UserId:** If [explicitUserId] is provided, it will be used instead of [userInfo.id].
  ///   This ensures the calculation is properly associated with the current authenticated user.
  ///
  /// Returns a [MacroResult] containing the calculated values.
  static MacroResult fromUserInfo(UserInfo userInfo, {String? explicitUserId}) {
    // Validate required fields
    if (userInfo.age == null ||
        userInfo.weight == null ||
        userInfo.feet == null ||
        userInfo.inches == null) {
      print('MacroResult: Missing required fields for calculation');
      // Return a default calculation with zeros
      return MacroResult(
        id: userInfo.id,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        calculationType: userInfo.goal.toString(),
        timestamp: userInfo.lastModified,
        isDefault: userInfo.isDefault,
        name: userInfo.name,
        lastModified: userInfo.lastModified,
        sourceProfile: userInfo,
        userId: explicitUserId ?? userInfo.id,
      );
    }

    // Height in cm
    double heightCm;
    if (userInfo.units == Units.imperial) {
      // Height: feet/inches to inches, then to cm
      heightCm = ((userInfo.feet ?? 0) * 12 + (userInfo.inches ?? 0)) * 2.54;
      print(
        'MacroResult: Imperial height conversion: ${userInfo.feet}\'${userInfo.inches}" = $heightCm cm',
      );
    } else {
      // Height: meters/centimeters to cm
      heightCm =
          ((userInfo.feet ?? 0) * 100) + (userInfo.inches ?? 0).toDouble();
      print(
        'MacroResult: Metric height conversion: ${userInfo.feet}m ${userInfo.inches}cm = $heightCm cm',
      );
    }

    // Weight in kg
    double weightKg =
        userInfo.units == Units.imperial
            ? (userInfo.weight ?? 0) * 0.453592
            : (userInfo.weight ?? 0);

    print(
      'MacroResult: Weight conversion: ${userInfo.weight} ${userInfo.units == Units.imperial ? "lbs" : "kg"} = $weightKg kg',
    );

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (userInfo.sex.toLowerCase() == 'female') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * (userInfo.age ?? 0) - 161;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * (userInfo.age ?? 0) + 5;
    }

    print('MacroResult: BMR calculation: $bmr calories');

    // Activity multipliers
    final activityMultipliers = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.lightlyActive: 1.375,
      ActivityLevel.moderatelyActive: 1.55,
      ActivityLevel.veryActive: 1.725,
      ActivityLevel.extraActive: 1.9,
    };
    double activityMultiplier =
        activityMultipliers[userInfo.activityLevel] ?? 1.2;

    print(
      'MacroResult: Activity multiplier: $activityMultiplier (${userInfo.activityLevel})',
    );

    // Calculate TDEE (Total Daily Energy Expenditure)
    double calories = bmr * activityMultiplier;
    print('MacroResult: TDEE: $calories calories');

    // Get weight change rate (default to 1.0 if not specified)
    double weightChangeRate = userInfo.weightChangeRate ?? 1.0;

    // Adjust calories based on goal and weight change rate
    // For imperial units (lbs): 1 lb = 3500 calories, so 1 lb/week = 500 calories/day
    // For metric units (kg): 1 kg = 7700 calories, so 1 kg/week = 1100 calories/day
    double calorieAdjustment =
        userInfo.units == Units.imperial
            ? weightChangeRate *
                500 // 500 calories per pound per week
            : weightChangeRate * 1100; // 1100 calories per kg per week

    switch (userInfo.goal) {
      case Goal.lose:
        calories -= calorieAdjustment;
        print(
          'MacroResult: Goal adjustment (lose): -$calorieAdjustment calories ($weightChangeRate ${userInfo.units == Units.imperial ? "lbs" : "kg"}/week)',
        );
        break;
      case Goal.gain:
        calories += calorieAdjustment;
        print(
          'MacroResult: Goal adjustment (gain): +$calorieAdjustment calories ($weightChangeRate ${userInfo.units == Units.imperial ? "lbs" : "kg"}/week)',
        );
        break;
      default:
        print('MacroResult: Goal adjustment (maintain): no change');
        break;
    }

    double originalCalories = calories;
    calories = calories.clamp(1200, 4000).toDouble();
    if (originalCalories != calories) {
      print(
        'MacroResult: Calories clamped from $originalCalories to $calories',
      );
    }

    // Macros
    double protein = weightKg * 1.8; // grams
    double fat = calories * 0.25 / 9; // grams
    double carbs = (calories - (protein * 4 + fat * 9)) / 4; // grams

    // Ensure carbs don't go negative (can happen with very low calorie diets)
    carbs = carbs < 0 ? 0 : carbs;

    print(
      'MacroResult: Final macros: $calories calories, $protein g protein, $carbs g carbs, $fat g fat',
    );

    return MacroResult(
      id: userInfo.id,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calculationType: userInfo.goal.toString(),
      timestamp: userInfo.lastModified,
      isDefault: userInfo.isDefault,
      name: userInfo.name,
      lastModified: userInfo.lastModified,
      sourceProfile: userInfo,
      userId: explicitUserId ?? userInfo.id,
    );
  }

  /// Converts this MacroResult back to a UserInfo.
  /// If sourceProfile is available, returns it. Otherwise, returns a default UserInfo.
  UserInfo toUserInfo() {
    return sourceProfile ??
        UserInfo(
          id: id,
          sex: 'male', // Default or update as needed
          activityLevel: ActivityLevel.moderatelyActive,
          goal: Goal.maintain,
          units: Units.metric,
          isDefault: isDefault,
          name: name,
          lastModified: lastModified ?? timestamp,
        );
  }

  /// Creates a MacroResult from a database map.
  /// This is used when retrieving data from the SQLite database.
  static MacroResult fromMap(Map<String, dynamic> map) {
    return MacroResult(
      id: map['id'],
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      calculationType: map['calculation_type'],
      timestamp:
          map['created_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
              : null,
      isDefault: map['is_default'] == 1,
      name: map['name'],
      lastModified:
          map['last_modified'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_modified'])
              : null,
      userId: map['user_id'],
    );
  }

  /// Converts this MacroResult to a map for database storage.
  /// This is used when storing data in the SQLite database.
  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calculation_type': calculationType,
      'created_at': timestamp?.millisecondsSinceEpoch ?? now,
      'updated_at': now,
      'is_default': isDefault ? 1 : 0,
      'name': name,
      'last_modified': lastModified?.millisecondsSinceEpoch ?? now,
      'user_id': userId,
    };
  }
}
