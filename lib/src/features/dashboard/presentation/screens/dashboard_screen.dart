import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../profile/presentation/providers/user_info_provider.dart';
import '../../../profile/domain/entities/user_info.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../calculator/domain/entities/macro_result.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfosAsync = ref.watch(userInfoProvider);
    final defaultMacroAsync = ref.watch(defaultMacroProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: userInfosAsync.when(
          data: (userInfos) {
            final userInfo = userInfos.isNotEmpty ? userInfos.first : null;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      'Welcome${userInfo?.name != null ? ", ${userInfo!.name}" : ""}',
                      textAlign: TextAlign.center,
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Your Dashboard',
                            style: textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (userInfo != null)
                          _buildUserInfoCard(context, userInfo),
                        const SizedBox(height: 24),
                        _buildDefaultMacroCard(context, defaultMacroAsync, ref),
                        const SizedBox(height: 24),
                        _buildFeatureCards(context),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) =>
                  Center(child: Text('Error loading profile: $error')),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserInfo userInfo) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Add debug information to verify user profile data
    print('UserInfo Debug:');
    print('ID: ${userInfo.id}');
    print('Name: ${userInfo.name}');
    print('Age: ${userInfo.age}');
    print('Sex: ${userInfo.sex}');
    print('Weight: ${userInfo.weight}');
    print('Height: ${userInfo.feet}\'${userInfo.inches}"');
    print('Units: ${userInfo.units}');
    print('Activity Level: ${userInfo.activityLevel}');
    print('Goal: ${userInfo.goal}');
    print('Is Default: ${userInfo.isDefault}');
    print('Last Modified: ${userInfo.lastModified}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo.name ?? 'User',
                        style: textTheme.titleLarge,
                      ),
                      Text(
                        'Goal: ${_getGoalText(userInfo.goal)}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  'Weight',
                  userInfo.weight != null
                      ? '${userInfo.weight} ${userInfo.units == Units.imperial ? 'lbs' : 'kg'}'
                      : 'N/A',
                ),
                _buildStatColumn(
                  context,
                  'Height',
                  userInfo.units == Units.imperial && userInfo.feet != null
                      ? '${userInfo.feet}\'${userInfo.inches ?? 0}"'
                      : 'N/A',
                ),
                _buildStatColumn(
                  context,
                  'Activity',
                  _getActivityText(userInfo.activityLevel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/profile');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('View Full Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }

  Widget _buildDefaultMacroCard(
    BuildContext context,
    AsyncValue<MacroResult?> defaultMacroAsync,
    ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Add debug information about the current state
    print(
      'Dashboard: defaultMacroAsync state: ${defaultMacroAsync.runtimeType}',
    );
    if (defaultMacroAsync is AsyncError) {
      print(
        'Dashboard: defaultMacroAsync error: ${(defaultMacroAsync as AsyncError).error}',
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Macro Calculation', style: textTheme.titleLarge),
                Icon(Icons.calculate, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            defaultMacroAsync.when(
              data: (macroResult) {
                if (macroResult == null) {
                  return const Center(
                    child: Text(
                      'No default macro calculation found.\nCreate one in the calculator.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Add debug information to verify macro calculation
                print('MacroResult Debug:');
                print('ID: ${macroResult.id}');
                print('Name: ${macroResult.name}');
                print('Calories: ${macroResult.calories}');
                print('Protein: ${macroResult.protein}');
                print('Carbs: ${macroResult.carbs}');
                print('Fat: ${macroResult.fat}');
                print('Calculation Type: ${macroResult.calculationType}');
                print('Is Default: ${macroResult.isDefault}');
                print('Last Modified: ${macroResult.lastModified}');
                if (macroResult.sourceProfile != null) {
                  print('Source Profile ID: ${macroResult.sourceProfile?.id}');
                  print(
                    'Source Profile Units: ${macroResult.sourceProfile?.units}',
                  );
                }

                // Check if the macro result has valid values
                if (macroResult.calories <= 0 || macroResult.protein <= 0) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Incomplete macro calculation data',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to calculator to create a new calculation
                            context.push('/calculator');
                          },
                          child: const Text('Create New Calculation'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add calculation name if available
                    if (macroResult.name != null &&
                        macroResult.name!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          macroResult.name!,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Add calculation type if available
                    if (macroResult.calculationType != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          _getCalculationTypeText(macroResult.calculationType),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    _buildMacroRow(
                      context,
                      'Calories',
                      '${macroResult.calories.round()} kcal',
                    ),
                    const SizedBox(height: 8),
                    _buildMacroRow(
                      context,
                      'Protein',
                      '${macroResult.protein.round()} g',
                    ),
                    const SizedBox(height: 8),
                    _buildMacroRow(
                      context,
                      'Carbohydrates',
                      '${macroResult.carbs.round()} g',
                    ),
                    const SizedBox(height: 8),
                    _buildMacroRow(
                      context,
                      'Fat',
                      '${macroResult.fat.round()} g',
                    ),
                    // Add a button to recalculate
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/calculator');
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recalculate'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                // Log the error for debugging
                print('Error loading macro calculation: $error');
                print('Stack trace: $stackTrace');

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error loading macro calculation',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(defaultMacroProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to convert calculation type to user-friendly text
  String _getCalculationTypeText(String? calculationType) {
    if (calculationType == null) return 'Standard Calculation';

    switch (calculationType) {
      case 'Goal.lose':
        return 'Weight Loss Plan';
      case 'Goal.maintain':
        return 'Maintenance Plan';
      case 'Goal.gain':
        return 'Muscle Gain Plan';
      case 'default_fallback':
        return 'Default Recommendation';
      case 'error_fallback':
        return 'Recommended Values';
      default:
        if (calculationType.startsWith('Goal.')) {
          return '${calculationType.substring(5)} Plan';
        }
        return calculationType;
    }
  }

  Widget _buildMacroRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              'Calculate Macros',
              Icons.calculate,
              () => context.push('/calculator'),
            ),
            _buildFeatureCard(
              context,
              'Meal Plans',
              Icons.restaurant_menu,
              () => context.push('/meal-plans'),
            ),
            _buildFeatureCard(
              context,
              'Progress',
              Icons.trending_up,
              () => context.push('/progress'),
            ),
            _buildFeatureCard(
              context,
              'Settings',
              Icons.settings,
              () => context.push('/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getGoalText(Goal goal) {
    switch (goal) {
      case Goal.lose:
        return 'Lose Weight';
      case Goal.maintain:
        return 'Maintain Weight';
      case Goal.gain:
        return 'Gain Muscle';
    }
  }

  String _getActivityText(ActivityLevel level) {
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
