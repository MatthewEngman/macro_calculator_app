import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../calculator/domain/entities/macro_result.dart';

class SavedMacroCard extends StatelessWidget {
  final MacroResult macro;

  const SavedMacroCard({super.key, required this.macro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (macro.timestamp != null)
              Text(
                dateFormat.format(macro.timestamp!),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
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
                      const SizedBox(height: 4),
                      Text(
                        'Daily Calories',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'P: ${macro.protein.toStringAsFixed(0)}g  '
                  'C: ${macro.carbs.toStringAsFixed(0)}g  '
                  'F: ${macro.fat.toStringAsFixed(0)}g',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
