import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/meal_plan.dart';
import '../../data/meal_plan_db.dart';

class MealPlanResultScreen extends StatelessWidget {
  final MealPlan mealPlan;

  const MealPlanResultScreen({super.key, required this.mealPlan});

  Future<void> _updateFeedback(BuildContext context, String feedback) async {
    try {
      // Update the meal plan with feedback
      if (mealPlan.id == null) {
        throw Exception('Cannot update feedback: meal plan has no ID');
      }
      await MealPlanDB.updateFeedback(mealPlan.id!, feedback);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving feedback: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Meal Plan'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Diet and Goal
            Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mealPlan.diet.toUpperCase()} Diet for ${mealPlan.goal}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created on ${mealPlan.timestamp.toString().split('.')[0]}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Macro Summary Card
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Macro Goals',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroWidget(
                            label: 'Calories',
                            value: mealPlan.macros['calories']!,
                            unit: 'kcal',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Protein',
                            value: mealPlan.macros['protein']!,
                            unit: 'g',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Carbs',
                            value: mealPlan.macros['carbs']!,
                            unit: 'g',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Fat',
                            value: mealPlan.macros['fat']!,
                            unit: 'g',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients
            Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          mealPlan.ingredients
                              .map(
                                (ingredient) => Chip(label: Text(ingredient)),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meal Plan Card
            Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Meal Plan',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mealPlan.plan,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Feedback Card
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How\'s this meal plan?',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FeedbackButton(
                          icon: Icons.thumb_up,
                          label: 'Like',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                          onPressed: () => _updateFeedback(context, 'liked'),
                        ),
                        _FeedbackButton(
                          icon: Icons.thumb_down,
                          label: 'Dislike',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                          onPressed: () => _updateFeedback(context, 'disliked'),
                        ),
                        _FeedbackButton(
                          icon: Icons.refresh,
                          label: 'Regenerate',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                          onPressed: () => context.go('/meal-plans/generate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MacroWidget extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  final Color textColor;

  const _MacroWidget({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(label, style: textTheme.titleSmall?.copyWith(color: textColor)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: textTheme.bodyMedium?.copyWith(color: textColor)),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const _FeedbackButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textColor),
      label: Text(label, style: TextStyle(color: textColor)),
    );
  }
}
