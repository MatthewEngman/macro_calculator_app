import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as persistence;
import '../../../calculator/domain/entities/macro_result.dart';
import '../providers/profile_provider.dart';

class SavedMacroCard extends ConsumerWidget {
  final MacroResult macro;
  final VoidCallback? onTap;

  const SavedMacroCard({super.key, required this.macro, this.onTap});

  Future<void> _confirmAndSetDefault(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check if macro.id is null
    if (macro.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot set as default: Invalid macro ID'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set as Default?'),
            content: const Text(
              'Are you sure you want to set this macro as your default?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      // Get the current user ID from Firebase
      final auth = ref.read(persistence.firebaseAuthProvider);
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot set as default: User not authenticated'),
          ),
        );
        return;
      }

      // Now we can safely use macro.id! since we've checked it's not null
      await ref
          .read(profileProvider.notifier)
          .setDefaultMacro(macro.id!, userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Default macro updated!')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print(
      'SavedMacroCard: id=${macro.id}, isDefault=${macro.isDefault}, name=${macro.name}, timestamp=${macro.timestamp}',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap:
            onTap ??
            () {
              _showMacroDetailsDialog(context, ref);
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (macro.timestamp != null)
                    Text(
                      dateFormat.format(macro.timestamp!),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  // Use ternary for correct Dart conditional collection syntax
                  (macro.isDefault
                      ? Row(
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
                      )
                      : IconButton(
                        icon: const Icon(Icons.star_border, color: Colors.grey),
                        tooltip: 'Set as Default',
                        onPressed: () => _confirmAndSetDefault(context, ref),
                      )),
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
                          '${macro.calories.toStringAsFixed(0)} cal',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Add more macro details here if needed
                      ],
                    ),
                  ),
                ],
              ),
              // ... Add more card content as needed ...
            ],
          ),
        ),
      ),
    );
  }

  // Dummy placeholder for macro details dialog
  void _showMacroDetailsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Macro Details'),
            content: Text('Show more details here.'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
