import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart';
import 'package:macro_masher/src/core/theme/app_theme.dart';
import '../../domain/entities/user_info.dart';
import '../providers/settings_provider.dart';

class UserInfoCard extends ConsumerWidget {
  final UserInfo userInfo;
  final VoidCallback? onTap;

  const UserInfoCard({super.key, required this.userInfo, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Skip rendering cards with null weight values
    if (userInfo.weight == null) {
      return const SizedBox.shrink(); // Don't display the card at all
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // Use Material 3 card styling
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap:
            onTap ??
            () {
              _showUserInfoDetailsDialog(context, ref);
            },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getGoalLabel(userInfo.goal),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (userInfo.isDefault)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Default',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userInfo.weight!.toStringAsFixed(1)} ${userInfo.units == Units.metric ? 'kg' : 'lbs'}',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getActivityLevelLabel(userInfo.activityLevel),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    userInfo.age != null ? 'Age: ${userInfo.age}' : '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserInfoDetailsDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final heightText =
        userInfo.units == Units.metric
            ? userInfo.inches != null
                ? '${userInfo.inches} cm'
                : 'Not set'
            : userInfo.feet != null && userInfo.inches != null
            ? '${userInfo.feet}\' ${userInfo.inches}"'
            : 'Not set';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                'Profile Details',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text('Weight'),
                  subtitle: Text(
                    userInfo.weight != null
                        ? '${userInfo.weight!.toStringAsFixed(1)} ${userInfo.units == Units.metric ? 'kg' : 'lbs'}'
                        : 'Not set',
                  ),
                  leading: Icon(
                    Icons.monitor_weight,
                    color: colorScheme.primary,
                  ),
                ),
                ListTile(
                  title: Text('Height'),
                  subtitle: Text(heightText),
                  leading: Icon(Icons.height, color: colorScheme.primary),
                ),
                ListTile(
                  title: Text('Age'),
                  subtitle: Text(
                    userInfo.age != null ? '${userInfo.age} years' : 'Not set',
                  ),
                  leading: Icon(Icons.cake, color: colorScheme.primary),
                ),
                ListTile(
                  title: Text('Sex'),
                  subtitle: Text(userInfo.sex),
                  leading: Icon(Icons.person, color: colorScheme.primary),
                ),
                ListTile(
                  title: Text('Activity Level'),
                  subtitle: Text(
                    _getActivityLevelLabel(userInfo.activityLevel),
                  ),
                  leading: Icon(
                    Icons.directions_run,
                    color: colorScheme.primary,
                  ),
                ),
                ListTile(
                  title: Text('Goal'),
                  subtitle: Text(_getGoalLabel(userInfo.goal)),
                  leading: Icon(
                    Icons.track_changes,
                    color: colorScheme.primary,
                  ),
                ),
                ListTile(
                  title: Text('Units'),
                  subtitle: Text(
                    userInfo.units == Units.metric
                        ? 'Metric (kg, cm)'
                        : 'Imperial (lbs, ft/in)',
                  ),
                  leading: Icon(Icons.straighten, color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditProfileDialog(context, ref);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: AppTheme.filledButtonStyle(context),
                    ),
                    if (userInfo.isDefault)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Default Profile',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () async {
                          if (userInfo.id != null) {
                            final auth = ref.read(firebaseAuthProvider);
                            final userId = auth.currentUser?.uid;
                            if (userId != null) {
                              final syncService = await ref.read(
                                firestoreSyncServiceProvider.future,
                              );
                              await syncService.setDefaultUserInfo(
                                userId,
                                userInfo.id!,
                              );
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Set as default profile',
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.star_outline, color: Colors.amber),
                        label: const Text('Set as Default'),
                        style: AppTheme.filledButtonStyle(context),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to calculator screen with prefilled data
                      context.push('/', extra: userInfo);
                    },
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate with this Profile'),
                    style: AppTheme.filledButtonStyle(context),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    _showCalculationInfoDialog(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'How are macros calculated?',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Controllers with prefilled values
    final weightController = TextEditingController(
      text: userInfo.weight?.toString() ?? '',
    );
    final feetController = TextEditingController(
      text: userInfo.feet?.toString() ?? '',
    );
    final inchesController = TextEditingController(
      text: userInfo.inches?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: userInfo.age?.toString() ?? '',
    );

    // Initialize with current values
    var sex = userInfo.sex;
    var activityLevel = userInfo.activityLevel;
    var goal = userInfo.goal;
    var units = userInfo.units;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                      suffixText: 'kg/lbs',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  if (units == Units.imperial) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
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
                          child: TextFormField(
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
                  ] else ...[
                    TextFormField(
                      controller: inchesController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      suffixText: 'years',
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
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
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
                        ActivityLevel.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(_getActivityLevelLabel(a)),
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
                onPressed: () async {
                  // Update user info with edited values
                  final updatedUserInfo = userInfo.copyWith(
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

                  // Get the current user ID
                  final authInstance = ref.read(firebaseAuthProvider);
                  final userId = authInstance.currentUser?.uid;

                  if (userId != null) {
                    // Save updated user info
                    final syncService = await ref.read(
                      firestoreSyncServiceProvider.future,
                    );
                    await syncService.saveUserInfo(userId, updatedUserInfo);
                    // Close dialog
                    Navigator.of(context).pop();
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile updated successfully',
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        backgroundColor: colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    // Handle the case where user is not authenticated
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: User not authenticated',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        backgroundColor: colorScheme.errorContainer,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showCalculationInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                'Macro Calculation Method',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    context,
                    'Basal Metabolic Rate (BMR)',
                    'We calculate your BMR using the Harris-Benedict equation:\n\n'
                        '• Male: 66 + (6.23 × weight in lbs) + (12.7 × height in inches) - (6.8 × age)\n'
                        '• Female: 655 + (4.35 × weight in lbs) + (4.7 × height in inches) - (4.7 × age)',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Activity Multiplier',
                    'Your BMR is multiplied by an activity factor:\n\n'
                        '• Sedentary: 1.2\n'
                        '• Lightly Active: 1.375\n'
                        '• Moderately Active: 1.55\n'
                        '• Very Active: 1.725\n'
                        '• Extra Active: 1.9',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Target Calories',
                    'Based on your goal:\n\n'
                        '• Maintain: Maintenance calories\n'
                        '• Lose: Maintenance - (weight change rate × 500)\n'
                        '• Gain: Maintenance + (weight change rate × 500)',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Macronutrient Breakdown',
                    '• Protein: 1g per pound of body weight\n'
                        '• Fat: 25% of total calories (9 calories per gram)\n'
                        '• Carbs: Remaining calories (4 calories per gram)',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ],
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
