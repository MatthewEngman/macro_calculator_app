import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class CalculationInputs extends ConsumerWidget {
  const CalculationInputs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Calculation Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ActivityLevel>(
                  value: settings.activityLevel,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                  ),
                  items:
                      ActivityLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(_getActivityLevelLabel(level)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(
                            CalculationSettings(
                              activityLevel: value,
                              goal: settings.goal,
                              units: settings.units,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Goal>(
                  value: settings.goal,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items:
                      Goal.values.map((goal) {
                        return DropdownMenuItem(
                          value: goal,
                          child: Text(_getGoalLabel(goal)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(
                            CalculationSettings(
                              activityLevel: settings.activityLevel,
                              goal: value,
                              units: settings.units,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Units>(
                  value: settings.units,
                  decoration: const InputDecoration(labelText: 'Units'),
                  items:
                      Units.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(_getUnitsLabel(unit)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSettings(
                            CalculationSettings(
                              activityLevel: settings.activityLevel,
                              goal: settings.goal,
                              units: value,
                            ),
                          );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getActivityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little or no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (exercise 1-3 times/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (exercise 3-5 times/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (exercise 6-7 times/week)';
      case ActivityLevel.extraActive:
        return 'Extra Active (very intense exercise daily)';
    }
  }

  String _getGoalLabel(Goal goal) {
    switch (goal) {
      case Goal.lose:
        return 'Lose Weight';
      case Goal.maintain:
        return 'Maintain Weight';
      case Goal.gain:
        return 'Gain Weight';
    }
  }

  String _getUnitsLabel(Units units) {
    switch (units) {
      case Units.imperial:
        return 'Imperial (lb, ft)';
      case Units.metric:
        return 'Metric (kg, cm)';
    }
  }
}
