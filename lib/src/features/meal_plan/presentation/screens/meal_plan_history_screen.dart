import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meal_plan.dart';
import 'package:go_router/go_router.dart';
import '../../services/meal_plan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/persistence/repository_providers.dart';

class MealPlanHistoryScreen extends ConsumerStatefulWidget {
  const MealPlanHistoryScreen({super.key});

  @override
  ConsumerState<MealPlanHistoryScreen> createState() =>
      _MealPlanHistoryScreenState();
}

class _MealPlanHistoryScreenState extends ConsumerState<MealPlanHistoryScreen> {
  late Future<List<MealPlan>> _mealPlansFuture;
  bool _isApiAvailable = true;

  @override
  void initState() {
    super.initState();
    _initializeMealPlans();
    _checkApiAvailability();
  }

  Future<void> _initializeMealPlans() async {
    try {
      final repository = ref.read(mealPlanRepositorySQLiteProvider);
      setState(() {
        _mealPlansFuture = repository.getAllMealPlans();
      });
    } catch (e, stackTrace) {
      print('Error initializing meal plans: $e\n$stackTrace');
      setState(() {
        _mealPlansFuture = Future.error(e, stackTrace);
      });
    }
  }

  Future<void> _checkApiAvailability() async {
    try {
      final mealPlanService = MealPlanService();
      final isAvailable = await mealPlanService.isApiAvailable();
      if (mounted) {
        setState(() {
          _isApiAvailable = isAvailable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApiAvailable = false;
        });
      }
    }
  }

  Future<void> _refreshMealPlans() async {
    final repository = ref.read(mealPlanRepositorySQLiteProvider);
    setState(() {
      _mealPlansFuture = repository.getAllMealPlans();
    });
    _checkApiAvailability();
  }

  Future<void> _deleteMealPlan(String id) async {
    try {
      final repository = ref.read(mealPlanRepositorySQLiteProvider);
      await repository.deleteMealPlan(id);
      await _refreshMealPlans();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal Plan deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting meal plan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Meal Plan History'),
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
            icon: const Icon(Icons.add),
            onPressed:
                _isApiAvailable
                    ? () => context.go('/meal-plans/generate')
                    : null,
            tooltip:
                _isApiAvailable
                    ? 'Generate New Meal Plan'
                    : 'Service Unavailable',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Unavailable Warning
          if (!_isApiAvailable)
            Container(
              width: double.infinity,
              color: colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 18, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Meal plan generation is currently unavailable',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkApiAvailability,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Retry',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<MealPlan>>(
              future: _mealPlansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle error by showing empty state instead of error
                final mealPlans = snapshot.data ?? [];

                if (mealPlans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meal plans yet',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate a meal plan to see it here',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (!_isApiAvailable)
                          Text(
                            'Service currently unavailable',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshMealPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mealPlans.length,
                    itemBuilder: (context, index) {
                      final plan = mealPlans[index];
                      return _MealPlanHistoryCard(
                        mealPlan: plan,
                        onTap: () {
                          context.go('/meal-plans/result', extra: plan);
                        },
                        onDelete: () => _deleteMealPlan(plan.id!),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPlanHistoryCard extends StatelessWidget {
  final MealPlan mealPlan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealPlanHistoryCard({
    required this.mealPlan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
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
                      'Generated: ${mealPlan.createdAt != null ? dateFormat.format(mealPlan.createdAt!) : 'N/A'}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: onDelete,
                    tooltip: 'Delete Plan',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Time: ${mealPlan.createdAt != null ? timeFormat.format(mealPlan.createdAt!) : 'N/A'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calories: ${mealPlan.totalCalories?.toStringAsFixed(0) ?? 'N/A'} kcal',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${mealPlan.totalCalories?.toStringAsFixed(0) ?? 'N/A'} kcal',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    mealPlan.createdAt != null
                        ? '${dateFormat.format(mealPlan.createdAt!)} at ${timeFormat.format(mealPlan.createdAt!)}'
                        : 'N/A',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
