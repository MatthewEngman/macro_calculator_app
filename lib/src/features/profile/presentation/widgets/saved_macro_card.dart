import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      await ref.read(profileProvider.notifier).setDefaultMacro(macro.id!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Default macro updated!')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
