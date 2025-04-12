import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../../profile/domain/entities/user_info.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  final UserInfo? userInfo;

  const CalculatorScreen({super.key, this.userInfo});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _weightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _cmController =
      TextEditingController(); // Separate controller for metric height
  final _ageController = TextEditingController();
  String _selectedSex = 'male';
  ActivityLevel _selectedActivityLevel = ActivityLevel.sedentary;
  Goal _selectedGoal = Goal.maintain;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // Set safe default values without accessing providers or database
    _selectedSex = 'male';
    _selectedActivityLevel = ActivityLevel.sedentary;
    _selectedGoal = Goal.maintain;

    // Schedule initialization after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitialize();
    });
  }

  void _safeInitialize() {
    if (!mounted) return;

    try {
      // Try to read settings, but handle the case when they're not initialized
      final calculatorNotifier = ref.read(calculatorProvider.notifier);

      try {
        final settings = ref.read(settingsProvider);
        // Set values from settings if available
        calculatorNotifier.goal = settings.goal.name;
        calculatorNotifier.activityLevel = settings.activityLevel.name;
        _selectedGoal = settings.goal;
        _selectedActivityLevel = settings.activityLevel;
      } catch (e) {
        // If settings aren't available, use defaults
        debugPrint('Error reading settings: $e');
        calculatorNotifier.goal = Goal.maintain.name;
        calculatorNotifier.activityLevel = ActivityLevel.sedentary.name;
      }

      // Now try to load user-specific values
      if (widget.userInfo != null) {
        // Pre-fill with user info
        final userInfo = widget.userInfo!;

        // Set text controllers
        if (userInfo.weight != null) {
          _weightController.text = userInfo.weight!.toString();
          calculatorNotifier.weight = userInfo.weight!;
        }

        if (userInfo.feet != null) {
          _feetController.text = userInfo.feet!.toString();
          calculatorNotifier.feet = userInfo.feet!;
        }

        if (userInfo.inches != null) {
          _inchesController.text = userInfo.inches!.toString();
          calculatorNotifier.inches = userInfo.inches!;
        }

        if (userInfo.age != null) {
          _ageController.text = userInfo.age!.toString();
          calculatorNotifier.age = userInfo.age!;
        }

        // Set dropdowns
        _selectedSex = userInfo.sex;
        calculatorNotifier.sex = userInfo.sex;

        _selectedActivityLevel = userInfo.activityLevel;
        calculatorNotifier.activityLevel = userInfo.activityLevel.name;

        _selectedGoal = userInfo.goal;
        calculatorNotifier.goal = userInfo.goal.name;
      } else {
        // Try to load default macro to prefill calculator
        _loadDefaultMacroValues();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing calculator: $e');
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _cmController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data directly from context
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Try to safely read providers, but use defaults if they fail
    bool isMetric = false; // Default to imperial units
    String weightUnit = 'lbs';
    try {
      final settings = ref.read(settingsProvider);
      isMetric = settings.units == Units.metric;
      weightUnit = isMetric ? 'kg' : 'lbs';
    } catch (e) {
      debugPrint('Error reading settings: $e');
      // Keep the imperial defaults
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Form(
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
                    'Macro Calculator',
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
                      // Basic Information Card
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
                                  'Basic Information',
                                  style: textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Weight Input
                              InputField(
                                label: 'Weight ($weightUnit)',
                                hint: 'Enter your weight',
                                keyboardType: TextInputType.number,
                                controller: _weightController,
                                onChanged: (value) {
                                  try {
                                    final calculatorNotifier = ref.read(
                                      calculatorProvider.notifier,
                                    );
                                    calculatorNotifier.weight =
                                        double.tryParse(value) ?? 0.0;
                                  } catch (e) {
                                    debugPrint('Error updating weight: $e');
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Height Input - Conditional based on units
                              if (isMetric)
                                InputField(
                                  label: 'Height (cm)',
                                  hint: 'Enter your height in cm',
                                  keyboardType: TextInputType.number,
                                  controller: _cmController,
                                  onChanged: (value) {
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      final cm = int.tryParse(value) ?? 0;
                                      final totalInches = cm / 2.54;
                                      calculatorNotifier.feet =
                                          (totalInches / 12).floor();
                                      calculatorNotifier.inches =
                                          (totalInches % 12).round();
                                    } catch (e) {
                                      debugPrint('Error updating height: $e');
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your height';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: InputField(
                                        label: 'Feet',
                                        hint: 'ft',
                                        keyboardType: TextInputType.number,
                                        controller: _feetController,
                                        onChanged: (value) {
                                          try {
                                            final calculatorNotifier = ref.read(
                                              calculatorProvider.notifier,
                                            );
                                            calculatorNotifier.feet =
                                                int.tryParse(value) ?? 0;
                                          } catch (e) {
                                            debugPrint(
                                              'Error updating feet: $e',
                                            );
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter feet';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InputField(
                                        label: 'Inches',
                                        hint: 'in',
                                        keyboardType: TextInputType.number,
                                        controller: _inchesController,
                                        onChanged: (value) {
                                          try {
                                            final calculatorNotifier = ref.read(
                                              calculatorProvider.notifier,
                                            );
                                            calculatorNotifier.inches =
                                                int.tryParse(value) ?? 0;
                                          } catch (e) {
                                            debugPrint(
                                              'Error updating inches: $e',
                                            );
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter inches';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Age Input
                              InputField(
                                label: 'Age',
                                hint: 'Enter your age',
                                keyboardType: TextInputType.number,
                                controller: _ageController,
                                onChanged: (value) {
                                  try {
                                    final calculatorNotifier = ref.read(
                                      calculatorProvider.notifier,
                                    );
                                    calculatorNotifier.age =
                                        int.tryParse(value) ?? 0;
                                  } catch (e) {
                                    debugPrint('Error updating age: $e');
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your age';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Sex Selection
                              DropdownButtonFormField<String>(
                                value: _selectedSex,
                                decoration: const InputDecoration(
                                  labelText: 'Sex',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    ['male', 'female'].map((sex) {
                                      return DropdownMenuItem(
                                        value: sex,
                                        child: Text(
                                          sex.substring(0, 1).toUpperCase() +
                                              sex.substring(1),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSex = value;
                                    });
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      calculatorNotifier.sex = value;
                                    } catch (e) {
                                      debugPrint('Error updating sex: $e');
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Activity Level Card
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
                                  'Activity Level',
                                  style: textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<ActivityLevel>(
                                value: _selectedActivityLevel,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    ActivityLevel.values.map((level) {
                                      return DropdownMenuItem(
                                        value: level,
                                        child: Text(
                                          _getActivityLevelLabel(level),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedActivityLevel = value;
                                    });
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      calculatorNotifier.activityLevel =
                                          value.name;
                                    } catch (e) {
                                      debugPrint(
                                        'Error updating activity level: $e',
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Goal Card
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
                                  'Goal',
                                  style: textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<Goal>(
                                value: _selectedGoal,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    Goal.values.map((goal) {
                                      return DropdownMenuItem(
                                        value: goal,
                                        child: Text(_getGoalLabel(goal)),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedGoal = value;
                                    });
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      calculatorNotifier.goal = value.name;
                                    } catch (e) {
                                      debugPrint('Error updating goal: $e');
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              // Weight Change Rate Input
                              if (_selectedGoal != Goal.maintain)
                                InputField(
                                  label:
                                      'Weight Change Rate ($weightUnit/week)',
                                  hint: 'Enter rate in $weightUnit/week',
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      calculatorNotifier.weightChangeRate =
                                          double.tryParse(value); // Allow null
                                    } catch (e) {
                                      debugPrint(
                                        'Error updating weight change rate: $e',
                                      );
                                    }
                                  },
                                  validator: (value) {
                                    if (_selectedGoal == Goal.maintain) {
                                      return null;
                                    }
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a rate.';
                                    }
                                    final rate = double.tryParse(value);
                                    if (rate == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (rate <= 0) {
                                      return 'Rate must be greater than 0';
                                    }
                                    // Safe access to goal
                                    String goal = 'maintain';
                                    try {
                                      final calculatorNotifier = ref.read(
                                        calculatorProvider.notifier,
                                      );
                                      goal = calculatorNotifier.goal;
                                    } catch (e) {
                                      debugPrint('Error reading goal: $e');
                                      goal = _selectedGoal.name;
                                    }
                                    final maxRate =
                                        isMetric
                                            ? (goal == 'lose' ? 0.9 : 0.45)
                                            : // 2 lbs = ~0.9 kg, 1 lb = ~0.45 kg
                                            (goal == 'lose' ? 2.0 : 1.0);
                                    if (rate > maxRate) {
                                      return 'The safe recommended weight ${goal == 'lose' ? 'loss' : 'gain'} is up to $maxRate $weightUnit a week';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Calculate Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton.icon(
                          onPressed: () {
                            try {
                              if (_formKey.currentState!.validate()) {
                                // Prepare the calculator with correct height values based on unit system
                                final calculatorNotifier = ref.read(
                                  calculatorProvider.notifier,
                                );

                                // For imperial units, make sure both feet and inches are set
                                if (!isMetric) {
                                  // Ensure feet is set
                                  if (_feetController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please enter your height in feet',
                                        ),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                    return;
                                  }

                                  // Convert feet/inches to cm for calculation if needed
                                  final feet =
                                      int.tryParse(_feetController.text) ?? 0;
                                  final inches =
                                      int.tryParse(_inchesController.text) ?? 0;
                                  calculatorNotifier.feet = feet;
                                  calculatorNotifier.inches = inches;
                                } else {
                                  // For metric, ensure cm is set
                                  if (_cmController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please enter your height in cm',
                                        ),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                    return;
                                  }

                                  // Set heightInCm directly
                                  final cm =
                                      int.tryParse(_cmController.text) ?? 0;

                                  // Convert to feet/inches for compatibility
                                  final totalInches = cm / 2.54;
                                  calculatorNotifier.feet =
                                      (totalInches / 12).floor();
                                  calculatorNotifier.inches =
                                      (totalInches % 12).round();
                                }

                                // Reset weight change rate if goal is maintain
                                if (calculatorNotifier.goal == 'maintain') {
                                  calculatorNotifier.weightChangeRate = null;
                                }

                                // Calculate macros and navigate to results
                                final result =
                                    calculatorNotifier.calculateMacros();
                                if (result != null) {
                                  context.push('/result', extra: result);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not calculate macros. Please check your inputs.',
                                      ),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error calculating macros: $e');
                              // Show error message to user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error calculating macros: ${e.toString()}',
                                  ),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calculate Macros'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalLabel(Goal goal) {
    switch (goal) {
      case Goal.lose:
        return 'Lose Weight';
      case Goal.maintain:
        return 'Maintain Weight';
      case Goal.gain:
        return 'Gain Weight';
    }
  }

  String _getActivityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extraActive:
        return 'Extra Active';
    }
  }

  void _showCalculationInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                'Macro Calculation Method',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    context,
                    'Basal Metabolic Rate (BMR)',
                    'We calculate your BMR using the Harris-Benedict equation:\n\n'
                        '• Male: 66 + (6.23 × weight in lbs) + (12.7 × height in inches) - (6.8 × age)\n'
                        '• Female: 655 + (4.35 × weight in lbs) + (4.7 × height in inches) - (4.7 × age)',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Activity Multiplier',
                    'Your BMR is multiplied by an activity factor:\n\n'
                        '• Sedentary: 1.2\n'
                        '• Lightly Active: 1.375\n'
                        '• Moderately Active: 1.55\n'
                        '• Very Active: 1.725\n'
                        '• Extra Active: 1.9',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Target Calories',
                    'Based on your goal:\n\n'
                        '• Maintain: Maintenance calories\n'
                        '• Lose: Maintenance - (weight change rate × 500)\n'
                        '• Gain: Maintenance + (weight change rate × 500)',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    context,
                    'Macronutrient Breakdown',
                    '• Protein: 1g per pound of body weight\n'
                        '• Fat: 25% of total calories (9 calories per gram)\n'
                        '• Carbs: Remaining calories (4 calories per gram)',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ],
    );
  }

  // Load default macro values if available - simplified to avoid database access
  Future<void> _loadDefaultMacroValues() async {
    // Skip database access entirely for now to avoid read-only errors
    // Just use the default values that were already set in initState
    debugPrint('Using default values instead of loading from database');
    return;
  }
}
