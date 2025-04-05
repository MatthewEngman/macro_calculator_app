import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class CalculationInputs extends ConsumerWidget {
  const CalculationInputs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Settings',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                // Activity Level
                DropdownButtonFormField<ActivityLevel>(
                  value: settings.activityLevel,
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: colorScheme.surface,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Activity level updated'),
                          backgroundColor: colorScheme.secondaryContainer,
                          behavior: SnackBarBehavior.floating,
                          showCloseIcon: true,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Goal
                DropdownButtonFormField<Goal>(
                  value: settings.goal,
                  decoration: InputDecoration(
                    labelText: 'Goal',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Goal updated'),
                          backgroundColor: colorScheme.secondaryContainer,
                          behavior: SnackBarBehavior.floating,
                          showCloseIcon: true,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Units
                DropdownButtonFormField<Units>(
                  value: settings.units,
                  decoration: InputDecoration(
                    labelText: 'Units',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Units updated'),
                          backgroundColor: colorScheme.secondaryContainer,
                          behavior: SnackBarBehavior.floating,
                          showCloseIcon: true,
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
