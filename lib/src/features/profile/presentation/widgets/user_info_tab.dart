import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_info.dart';
import '../providers/user_info_provider.dart';
import '../providers/settings_provider.dart';
import 'user_info_card.dart';

class UserInfoTab extends ConsumerWidget {
  const UserInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfos = ref.watch(userInfoProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return userInfos.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved profiles yet',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your saved profiles will appear here',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    _showAddProfileDialog(context, ref);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Profile'),
                ),
              ],
            ),
          );
        }
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final userInfo = data[index];
                return Dismissible(
                  key: Key(userInfo.id ?? ''),
                  background: Container(
                    color: colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.delete,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  direction:
                      userInfo.isDefault
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                  onDismissed: (direction) {
                    if (userInfo.id != null && !userInfo.isDefault) {
                      ref
                          .read(userInfoProvider.notifier)
                          .deleteUserInfo(userInfo.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Profile deleted',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          backgroundColor: colorScheme.secondaryContainer,
                          showCloseIcon: true,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: UserInfoCard(userInfo: userInfo),
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  _showAddProfileDialog(context, ref);
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading profiles',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.read(settingsProvider);

    // Form controllers
    final weightController = TextEditingController();
    final feetController = TextEditingController();
    final inchesController = TextEditingController();
    final ageController = TextEditingController();

    // Default values
    ActivityLevel activityLevel = settings.activityLevel;
    Goal goal = settings.goal;
    Units units = settings.units;
    String sex = 'male';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New Profile'),
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText:
                          'Weight (${units == Units.metric ? 'kg' : 'lbs'})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  if (units == Units.metric)
                    TextField(
                      controller: inchesController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: feetController,
                            decoration: const InputDecoration(
                              labelText: 'Feet',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: inchesController,
                            decoration: const InputDecoration(
                              labelText: 'Inches',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: sex,
                    decoration: const InputDecoration(
                      labelText: 'Sex',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ['male', 'female'].map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.substring(0, 1).toUpperCase() + s.substring(1),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        sex = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ActivityLevel>(
                    value: activityLevel,
                    decoration: const InputDecoration(
                      labelText: 'Activity Level',
                      border: OutlineInputBorder(),
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
                        activityLevel = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Goal>(
                    value: goal,
                    decoration: const InputDecoration(
                      labelText: 'Goal',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        Goal.values.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(_getGoalLabel(g)),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        goal = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Units>(
                    value: units,
                    decoration: const InputDecoration(
                      labelText: 'Units',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        Units.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(
                              u == Units.metric
                                  ? 'Metric (kg, cm)'
                                  : 'Imperial (lbs, ft/in)',
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        units = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  // Create new user info
                  final userInfo = UserInfo(
                    weight: double.tryParse(weightController.text),
                    feet:
                        units == Units.imperial
                            ? int.tryParse(feetController.text)
                            : null,
                    inches:
                        units == Units.imperial
                            ? int.tryParse(inchesController.text)
                            : int.tryParse(inchesController.text),
                    age: int.tryParse(ageController.text),
                    sex: sex,
                    activityLevel: activityLevel,
                    goal: goal,
                    units: units,
                  );

                  // Save user info
                  ref.read(userInfoProvider.notifier).saveUserInfo(userInfo);

                  // Close dialog
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Profile saved successfully',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
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

  String _getActivityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extraActive:
        return 'Extra Active';
    }
  }
}
