import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/meal_plan.dart';
import 'dart:convert';

class MealPlanResultScreen extends ConsumerWidget {
  final MealPlan mealPlan;

  const MealPlanResultScreen({super.key, required this.mealPlan});

  Widget _buildMealsSection(BuildContext context) {
    if (mealPlan.meals == null || mealPlan.meals!.isEmpty) {
      return const Text('No meal details available.');
    }
    try {
      final List<dynamic> mealsList = jsonDecode(mealPlan.meals!);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            mealsList.map((meal) {
              final mealName = meal['name'] ?? 'Unnamed Meal';
              final mealDetails = meal.toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('$mealName: $mealDetails'),
              );
            }).toList(),
      );
    } catch (e) {
      print('Error decoding meals JSON: $e');
      return Text('Meal Details (raw):\n${mealPlan.meals}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   '${mealPlan.diet.toUpperCase()} Diet for ${mealPlan.goal}',
                    //   style: textTheme.titleMedium?.copyWith(
                    //     color: colorScheme.onSecondaryContainer,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    Text(
                      'Created on: ${mealPlan.createdAt?.toString().split(' ')[0] ?? 'N/A'}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                            value: mealPlan.totalCalories ?? 0.0,
                            unit: 'kcal',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Protein',
                            value: mealPlan.totalProtein ?? 0.0,
                            unit: 'g',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Carbs',
                            value: mealPlan.totalCarbs ?? 0.0,
                            unit: 'g',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroWidget(
                            label: 'Fat',
                            value: mealPlan.totalFat ?? 0.0,
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
                      'Meal Totals',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMacroRow(
                      context,
                      'Total Calories:',
                      '${mealPlan.totalCalories?.toStringAsFixed(0) ?? 'N/A'} kcal',
                    ),
                    _buildMacroRow(
                      context,
                      'Total Protein:',
                      '${mealPlan.totalProtein?.toStringAsFixed(1) ?? 'N/A'} g',
                    ),
                    _buildMacroRow(
                      context,
                      'Total Carbs:',
                      '${mealPlan.totalCarbs?.toStringAsFixed(1) ?? 'N/A'} g',
                    ),
                    _buildMacroRow(
                      context,
                      'Total Fat:',
                      '${mealPlan.totalFat?.toStringAsFixed(1) ?? 'N/A'} g',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Meals:',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMealsSection(context),

                    const SizedBox(height: 16),
                    if (mealPlan.notes != null && mealPlan.notes!.isNotEmpty)
                      _buildSection(
                        context,
                        title: 'Notes',
                        content: Text(mealPlan.notes!),
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

  Widget _buildMacroRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

class _MacroWidget extends StatelessWidget {
  final String label;
  final double value;
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
