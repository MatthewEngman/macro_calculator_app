import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../providers/user_info_provider.dart';
import '../widgets/saved_macro_card.dart';
import '../widgets/user_info_tab.dart';
import '../../domain/entities/user_info.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/account_upgrade_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
          ),
          actions: [
            // Check if the user is anonymous
            if (ref.watch(authRepositoryProvider).currentUser?.isAnonymous ??
                false)
              IconButton(
                icon: const Icon(Icons.upgrade),
                tooltip: 'Upgrade Account',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountUpgradeScreen(),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  // First navigate to the sign-in page, then sign out
                  if (context.mounted) {
                    context.go('/signin');
                  }

                  // Small delay to ensure navigation completes
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Now sign out
                  await ref.read(authRepositoryProvider).signOut();

                  if (context.mounted) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Successfully logged out',
                          textAlign: TextAlign.center,
                        ),
                        behavior: SnackBarBehavior.floating,
                        width: 280,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error signing out: ${e.toString()}',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        width: 280,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          bottom: TabBar(
            labelColor: colorScheme.onSurface,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.history), text: 'Saved Results'),
              Tab(icon: Icon(Icons.person), text: 'Profiles'),
              Tab(icon: Icon(Icons.cloud), text: 'Firebase Test'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_SavedResultsTab(), UserInfoTab(), _FirestoreTestTab()],
        ),
      ),
    );
  }
}

class _SavedResultsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macros = ref.watch(profileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return macros.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved results yet',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your saved macro calculations will appear here',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final macro = data[index];

            return Dismissible(
              key: Key(macro.id ?? ''),
              background: Container(
                color: colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
              ),
              direction:
                  macro.isDefault
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
              onDismissed: (direction) {
                if (macro.id != null && !macro.isDefault) {
                  ref.read(profileProvider.notifier).deleteMacro(macro.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Result deleted',
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
                child: SavedMacroCard(macro: macro),
              ),
            );
          },
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
                  'Error loading saved results',
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
}

class _FirestoreTestTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfos = ref.watch(userInfoProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: userInfos.when(
        data: (data) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Firestore Integration Test',
                  style: textTheme.titleLarge,
                ),
              ),
              Expanded(
                child:
                    data.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No profiles in Firestore',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final userInfo = data[index];
                            return ListTile(
                              title: Text(
                                'Profile ${index + 1}${userInfo.isDefault ? ' (Default)' : ''}',
                              ),
                              subtitle: Text(
                                'Age: ${userInfo.age ?? 'N/A'}, Sex: ${userInfo.sex}, Goal: ${userInfo.goal}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.star,
                                      color:
                                          userInfo.isDefault
                                              ? Colors.amber
                                              : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      if (!userInfo.isDefault &&
                                          userInfo.id != null) {
                                        ref
                                            .read(userInfoProvider.notifier)
                                            .setDefaultUserInfo(userInfo.id!);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color:
                                          userInfo.isDefault
                                              ? colorScheme.onSurfaceVariant
                                                  .withOpacity(0.5)
                                              : colorScheme.error,
                                    ),
                                    onPressed:
                                        userInfo.isDefault
                                            ? null
                                            : () {
                                              if (userInfo.id != null) {
                                                ref
                                                    .read(
                                                      userInfoProvider.notifier,
                                                    )
                                                    .deleteUserInfo(
                                                      userInfo.id!,
                                                    );
                                              }
                                            },
                                  ),
                                ],
                              ),
                            );
                          },
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
                    'Error connecting to Firestore',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProfileDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController ageController = TextEditingController();
    String selectedSex = 'male';
    var selectedGoal = Goal.maintain;
    var selectedActivity = ActivityLevel.moderatelyActive;
    var selectedUnits = Units.imperial;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Test Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedSex = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Goal>(
                    value: selectedGoal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items:
                        Goal.values.map((goal) {
                          return DropdownMenuItem(
                            value: goal,
                            child: Text(goal.toString().split('.').last),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedGoal = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Create a new UserInfo object
                  final newUserInfo = UserInfo(
                    age: int.tryParse(ageController.text),
                    sex: selectedSex,
                    goal: selectedGoal,
                    activityLevel: selectedActivity,
                    units: selectedUnits,
                  );

                  // Save to Firestore
                  ref.read(userInfoProvider.notifier).saveUserInfo(newUserInfo);
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
