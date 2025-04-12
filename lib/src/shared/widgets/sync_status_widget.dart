import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/data_sync_manager.dart';
import '../../core/persistence/repository_providers.dart';

class SyncStatusWidget extends ConsumerWidget {
  final bool showLabel;
  final double iconSize;

  const SyncStatusWidget({
    super.key,
    this.showLabel = true,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncManager = ref.watch(dataSyncManagerProvider);

    return StreamBuilder<SyncStatus>(
      stream: syncManager.syncStatusStream,
      initialData: syncManager.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        return _buildStatusIndicator(context, status);
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, SyncStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = colorScheme.primary;
        label = 'Syncing...';
        break;
      case SyncStatus.synced:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Synced';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = colorScheme.error;
        label = 'Offline';
        break;
      case SyncStatus.error:
        icon = Icons.error_outline;
        color = colorScheme.error;
        label = 'Sync Error';
        break;
      case SyncStatus.notAuthenticated:
        icon = Icons.account_circle_outlined;
        color = colorScheme.error;
        label = 'Sign in to sync';
        break;
      case SyncStatus.idle:
      default:
        icon = Icons.cloud_queue;
        color = colorScheme.onSurfaceVariant;
        label = 'Waiting to sync';
        break;
    }

    if (status == SyncStatus.syncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

// Provider to easily access the sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncManager = ref.watch(dataSyncManagerProvider);
  return syncManager.syncStatusStream;
});
