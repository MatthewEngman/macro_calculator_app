import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/data_sync_manager.dart';
import '../../core/persistence/repository_providers.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncManager = ref.watch(dataSyncManagerProvider);

    return Scaffold(
      body: Column(
        children: [
          // Sync status indicator at the top
          StreamBuilder<SyncStatus>(
            stream: syncManager.syncStatusStream,
            initialData: syncManager.currentStatus,
            builder: (context, snapshot) {
              final status = snapshot.data ?? SyncStatus.idle;
              // Only show the banner for certain statuses
              if (status == SyncStatus.offline ||
                  status == SyncStatus.error ||
                  status == SyncStatus.notAuthenticated) {
                return _buildSyncStatusBanner(context, ref, status);
              }
              return const SizedBox.shrink();
            },
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(currentPath),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meal Plans',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      // Add a small sync status indicator in the bottom right
      floatingActionButton: StreamBuilder<SyncStatus>(
        stream: syncManager.syncStatusStream,
        initialData: syncManager.currentStatus,
        builder: (context, snapshot) {
          final status = snapshot.data ?? SyncStatus.idle;
          // Don't show FAB for offline/error statuses (already shown in banner)
          if (status == SyncStatus.offline ||
              status == SyncStatus.error ||
              status == SyncStatus.notAuthenticated) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.small(
            onPressed: () {
              // Manual sync when tapped
              syncManager.syncAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing data...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Sync data',
            child: _getSyncStatusIcon(status),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSyncStatusBanner(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color backgroundColor;
    String message;

    switch (status) {
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        backgroundColor = colorScheme.errorContainer;
        message = 'You\'re offline. Changes will be synced when you reconnect.';
        break;
      case SyncStatus.error:
        icon = Icons.error_outline;
        backgroundColor = colorScheme.errorContainer;
        message = 'Sync error. Tap to retry.';
        break;
      case SyncStatus.notAuthenticated:
        icon = Icons.account_circle_outlined;
        backgroundColor = colorScheme.primaryContainer;
        message = 'Sign in to sync your data across devices.';
        break;
      default:
        return _buildSyncStatusBanner(context, ref, status);
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          if (status == SyncStatus.error) {
            // Try to sync again on tap
            ref.read(dataSyncManagerProvider).syncAllData();
          } else if (status == SyncStatus.notAuthenticated) {
            // Navigate to sign-in screen
            context.go('/signin');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (status == SyncStatus.error ||
                  status == SyncStatus.notAuthenticated)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onErrorContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case SyncStatus.synced:
        return const Icon(Icons.check_circle);
      case SyncStatus.idle:
      default:
        return const Icon(Icons.sync);
    }
  }

  int _calculateSelectedIndex(String currentPath) {
    if (currentPath == '/' || currentPath.isEmpty) return 0;
    if (currentPath.startsWith('/calculator')) return 1;
    if (currentPath.startsWith('/meal-plans')) return 2;
    if (currentPath.startsWith('/profile')) return 3;
    if (currentPath.startsWith('/progress')) {
      return 0; // Show dashboard tab as active for progress
    }
    return 0; // Default to dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/'); // Dashboard
        break;
      case 1:
        context.go('/calculator');
        break;
      case 2:
        context.go('/meal-plans');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
