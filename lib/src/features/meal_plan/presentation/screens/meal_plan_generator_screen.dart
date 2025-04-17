import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart';
import '../../services/meal_plan_service.dart';
import '../../data/repositories/meal_plan_repository_sqlite_impl.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';

class MealPlanGeneratorScreen extends ConsumerStatefulWidget {
  const MealPlanGeneratorScreen({super.key});

  @override
  ConsumerState<MealPlanGeneratorScreen> createState() =>
      _MealPlanGeneratorScreenState();
}

class _MealPlanGeneratorScreenState
    extends ConsumerState<MealPlanGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealPlanService = MealPlanService();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final List<String> _ingredients = [];
  final _ingredientController = TextEditingController();

  String _selectedDiet = 'balanced';
  String _selectedGoal = 'maintenance';
  bool _isLoading = false;
  bool _isApiAvailable = true; // Track API availability
  bool _isCheckingApi = true; // Track if we're checking API status
  bool _isLoadingDefaultMacros = true; // Track if we're loading default macros

  final List<String> _dietTypes = [
    'balanced',
    'low-carb',
    'high-protein',
    'keto',
    'vegetarian',
    'vegan',
  ];

  final List<String> _goals = ['weight-loss', 'maintenance', 'muscle-gain'];

  @override
  void initState() {
    super.initState();
    _checkApiAvailability();
    _loadDefaultMacros();
  }

  // Check if the API is available
  Future<void> _checkApiAvailability() async {
    setState(() => _isCheckingApi = true);
    try {
      final isAvailable = await _mealPlanService.isApiAvailable();
      if (mounted) {
        setState(() {
          _isApiAvailable = isAvailable;
          _isCheckingApi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApiAvailable = false;
          _isCheckingApi = false;
        });
      }
    }
  }

  // Load default macros if available
  Future<void> _loadDefaultMacros() async {
    setState(() => _isLoadingDefaultMacros = true);
    try {
      // Get the default macro from the profile repository
      final profileRepository = ref.read(profileRepositoryProvider);
      final defaultMacro = await profileRepository.getDefaultMacro();

      // If default macro exists, prefill the form fields
      if (defaultMacro != null && mounted) {
        setState(() {
          _caloriesController.text = defaultMacro.calories.round().toString();
          _proteinController.text = defaultMacro.protein.round().toString();
          _carbsController.text = defaultMacro.carbs.round().toString();
          _fatController.text = defaultMacro.fat.round().toString();

          // Map goal from default macro to meal plan goal
          switch (defaultMacro.id?.split('_').lastOrNull) {
            case 'lose':
              _selectedGoal = 'weight-loss';
              break;
            case 'gain':
              _selectedGoal = 'muscle-gain';
              break;
            default:
              _selectedGoal = 'maintenance';
          }
        });
      }
    } catch (e) {
      // If there's an error, just continue without prefilling
      debugPrint('Error loading default macros: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDefaultMacros = false);
      }
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      setState(() {
        _ingredients.add(ingredient);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  Future<void> _generateMealPlan() async {
    if (!_formKey.currentState!.validate()) return;

    // Retrieve the current user profile state using the correct provider name
    // Note: The state type is AsyncValue<List<MacroResult>>, not UserInfo
    final userProfileState = ref.read(profileProvider);
    final localUserId = userProfileState.maybeWhen(
      data: (profile) => profile?.first.id, // Corrected this line
      orElse: () => null,
    );

    if (localUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Could not get user ID. Please ensure you are logged in.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use the service to get the meal plan object (from API or logic)
      final mealPlanFromService = await _mealPlanService.generateMealPlan(
        userId: localUserId, // Pass the userId
        diet: _selectedDiet,
        goal: _selectedGoal,
        macros: {
          'calories': double.parse(_caloriesController.text), // Parse as double
          'protein': double.parse(_proteinController.text), // Parse as double
          'carbs': double.parse(_carbsController.text), // Parse as double
          'fat': double.parse(_fatController.text), // Parse as double
        },
        ingredients: _ingredients,
      );

      // Add the necessary userId and potentially firebaseUserId before saving
      final firebaseUserId = ref.read(firebaseAuthProvider).currentUser?.uid;

      // Use the meal plan returned directly from the service
      final mealPlanToSave = mealPlanFromService.copyWith(
        // We might still need to add firebaseUserId if it's not handled by the service
        // or if we want it distinct from the local userId used for generation/local storage.
        firebaseUserId: firebaseUserId,
        // Ensure date is set correctly if needed for the plan itself
        date: DateTime.now().toIso8601String().substring(
          0,
          10,
        ), // Example: Set date to today
        // updatedAt/lastModified might be set by the DB or service later
      );

      // Get the repository using the correct provider by awaiting its future
      final mealPlanRepository = await ref.read(
        mealPlanRepositorySQLiteProvider.future,
      );
      final savedPlanId = await mealPlanRepository.saveMealPlan(mealPlanToSave);

      if (!mounted) return;

      if (savedPlanId != null) {
        // Fetch the saved plan to pass to the results screen (optional, could pass mealPlanToSave)
        final savedPlan = await mealPlanRepository.getMealPlanById(savedPlanId);
        if (savedPlan != null && mounted) {
          // Navigate to results screen
          context.go('/meal-plans/result', extra: savedPlan);
        } else if (mounted) {
          // Handle case where saved plan couldn't be re-fetched (shouldn't happen often)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Meal plan generated but could not navigate to results.',
              ),
            ),
          );
        }
      } else {
        // Handle case where saving failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving generated meal plan.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150.0,
              floating: false,
              pinned: true,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Meal Plan Generator',
                  textAlign: TextAlign.center,
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // API Unavailable Warning
                    if (!_isApiAvailable && !_isCheckingApi)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: colorScheme.errorContainer,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_off, color: colorScheme.error),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Service Unavailable',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Meal plan generation is currently unavailable. You can still view your saved meal plans.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: colorScheme.error,
                                ),
                                onPressed: _checkApiAvailability,
                                tooltip: 'Try again',
                              ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                'Diet Preferences',
                                style: textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDiet,
                              decoration: const InputDecoration(
                                labelText: 'Diet Type',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  _dietTypes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedDiet = newValue);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedGoal,
                              decoration: const InputDecoration(
                                labelText: 'Goal',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  _goals.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedGoal = newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                'Macro Goals',
                                style: textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _caloriesController,
                                    decoration: const InputDecoration(
                                      labelText: 'Calories',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter calories';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _proteinController,
                                    decoration: const InputDecoration(
                                      labelText: 'Protein (g)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter protein';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _carbsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Carbs (g)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter carbs';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _fatController,
                                    decoration: const InputDecoration(
                                      labelText: 'Fat (g)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter fat';
                                      }
                                      return null;
                                    },
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
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                'Ingredients',
                                style: textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ingredientController,
                                    decoration: const InputDecoration(
                                      labelText: 'Add Ingredient',
                                      border: OutlineInputBorder(),
                                    ),
                                    onFieldSubmitted: (_) => _addIngredient(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _addIngredient,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children:
                                  _ingredients.map((ingredient) {
                                    return Chip(
                                      label: Text(ingredient),
                                      onDeleted:
                                          () => _removeIngredient(ingredient),
                                      backgroundColor: colorScheme.surface,
                                      side: BorderSide(
                                        color: colorScheme.outline,
                                      ),
                                      deleteIconColor: colorScheme.onSurface,
                                      labelStyle: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          (_isLoading ||
                                  !_isApiAvailable ||
                                  _isCheckingApi ||
                                  _isLoadingDefaultMacros)
                              ? null
                              : _generateMealPlan,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : _isCheckingApi
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : _isLoadingDefaultMacros
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.restaurant_menu),
                      label: Text(
                        _isLoading
                            ? 'Generating...'
                            : _isCheckingApi
                            ? 'Checking service...'
                            : _isLoadingDefaultMacros
                            ? 'Loading default macros...'
                            : 'Generate Meal Plan',
                      ),
                    ),
                    if (!_isApiAvailable && !_isCheckingApi)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => context.go('/meal-plans/history'),
                            icon: const Icon(Icons.history),
                            label: const Text('View Saved Meal Plans'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
