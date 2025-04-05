import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meal_plan.dart';
import '../../data/meal_plan_db.dart';
import 'package:go_router/go_router.dart';

class MealPlanHistoryScreen extends StatefulWidget {
  const MealPlanHistoryScreen({super.key});

  @override
  State<MealPlanHistoryScreen> createState() => _MealPlanHistoryScreenState();
}

class _MealPlanHistoryScreenState extends State<MealPlanHistoryScreen> {
  late Future<List<MealPlan>> _mealPlansFuture;

  @override
  void initState() {
    super.initState();
    _mealPlansFuture = MealPlanDB.getAllPlans();
  }

  void _refreshMealPlans() {
    setState(() {
      _mealPlansFuture = MealPlanDB.getAllPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan History'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/meal-plans/generate'),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<List<MealPlan>>(
        future: _mealPlansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }

          final mealPlans = snapshot.data ?? [];

          if (mealPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_meals, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No meal plans yet',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/meal-plans/generate'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Meal Plan'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshMealPlans();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: mealPlans.length,
              itemBuilder: (context, index) {
                final plan = mealPlans[index];
                return _MealPlanHistoryCard(
                  mealPlan: plan,
                  onTap: () {
                    context.go('/meal-plans/result', extra: plan);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MealPlanHistoryCard extends StatelessWidget {
  final MealPlan mealPlan;
  final VoidCallback onTap;

  const _MealPlanHistoryCard({required this.mealPlan, required this.onTap});

  String _getFeedbackIcon() {
    switch (mealPlan.feedback.toLowerCase()) {
      case 'liked':
        return '👍';
      case 'disliked':
        return '👎';
      default:
        return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${mealPlan.diet.toUpperCase()} Diet',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    _getFeedbackIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${mealPlan.goal}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${mealPlan.macros['calories']} kcal',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${dateFormat.format(mealPlan.timestamp)} at ${timeFormat.format(mealPlan.timestamp)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
