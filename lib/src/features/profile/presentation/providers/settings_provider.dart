import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_masher/src/core/persistence/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

enum Goal { lose, maintain, gain }

enum Units { imperial, metric }

class CalculationSettings {
  final ActivityLevel activityLevel;
  final Goal goal;
  final Units units;

  const CalculationSettings({
    required this.activityLevel,
    required this.goal,
    required this.units,
  });

  factory CalculationSettings.fromJson(Map<String, dynamic> json) {
    return CalculationSettings(
      activityLevel: ActivityLevel.values[json['activityLevel'] ?? 0],
      goal: Goal.values[json['goal'] ?? 1],
      units: Units.values[json['units'] ?? 0],
    );
  }

  Map<String, dynamic> toJson() => {
    'activityLevel': activityLevel.index,
    'goal': goal.index,
    'units': units.index,
  };
}

class SettingsNotifier extends StateNotifier<CalculationSettings> {
  final SharedPreferences _prefs;
  static const _key = 'calculation_settings';

  SettingsNotifier(this._prefs)
    : super(
        CalculationSettings.fromJson(
          _prefs.getString(_key) != null
              ? Map<String, dynamic>.from(
                Map<String, dynamic>.from(
                  const CalculationSettings(
                    activityLevel: ActivityLevel.moderatelyActive,
                    goal: Goal.maintain,
                    units: Units.imperial,
                  ).toJson(),
                ),
              )
              : const CalculationSettings(
                activityLevel: ActivityLevel.moderatelyActive,
                goal: Goal.maintain,
                units: Units.imperial,
              ).toJson(),
        ),
      );

  Future<void> updateSettings(CalculationSettings settings) async {
    await _prefs.setString(_key, settings.toJson().toString());
    state = settings;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, CalculationSettings>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SettingsNotifier(prefs);
    });
