import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
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
    final isAnonymous = ref.watch(authRepositoryProvider).isUserAnonymous;

    return DefaultTabController(
      length: 2,
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
            tabs: const [Tab(text: 'Profile'), Tab(text: 'Saved')],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [const UserInfoTab(), const _SavedResultsTab()],
            ),
            // Show account upgrade banner for anonymous users
            if (isAnonymous)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You\'re using a guest account',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your data is only stored on this device. Sign in with Google to sync your data across devices and keep it safe.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const AccountUpgradeScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Upgrade Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedResultsTab extends ConsumerWidget {
  const _SavedResultsTab();

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
