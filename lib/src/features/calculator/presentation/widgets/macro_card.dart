import 'package:flutter/material.dart';

class MacroCard extends StatelessWidget {
  final String title;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const MacroCard({
    super.key,
    required this.title,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
