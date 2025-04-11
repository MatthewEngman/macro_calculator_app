import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../../profile/domain/entities/user_info.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/user_info_provider.dart';

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
  final _ageController = TextEditingController();
  String _selectedSex = 'male';
  ActivityLevel _selectedActivityLevel = ActivityLevel.sedentary;
  Goal _selectedGoal = Goal.maintain;

  // Flag to track if default macro was loaded
  bool _defaultMacroLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Initialize calculator with user info or default settings
      final settings = ref.read(settingsProvider);
      final calculator = ref.read(calculatorProvider.notifier);

      if (widget.userInfo != null) {
        // Pre-fill with user info
        final userInfo = widget.userInfo!;

        // Set text controllers
        if (userInfo.weight != null) {
          _weightController.text = userInfo.weight!.toString();
          calculator.weight = userInfo.weight!;
        }

        if (userInfo.feet != null) {
          _feetController.text = userInfo.feet!.toString();
          calculator.feet = userInfo.feet!;
        }

        if (userInfo.inches != null) {
          _inchesController.text = userInfo.inches!.toString();
          calculator.inches = userInfo.inches!;
        }

        if (userInfo.age != null) {
          _ageController.text = userInfo.age!.toString();
          calculator.age = userInfo.age!;
        }

        // Set dropdowns
        _selectedSex = userInfo.sex;
        calculator.sex = userInfo.sex;

        _selectedActivityLevel = userInfo.activityLevel;
        calculator.activityLevel = userInfo.activityLevel.name;

        _selectedGoal = userInfo.goal;
        calculator.goal = userInfo.goal.name;

        // Update state to refresh UI
        setState(() {});
      } else {
        // Try to load default macro to prefill calculator
        _loadDefaultMacroValues().then((_) {
          // If no default macro was loaded, use default settings
          if (!_defaultMacroLoaded) {
            calculator.goal = settings.goal.name;
            calculator.activityLevel = settings.activityLevel.name;
            _selectedGoal = settings.goal;
            _selectedActivityLevel = settings.activityLevel;
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorNotifier = ref.watch(calculatorProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isMetric = settings.units == Units.metric;
    final String weightUnit = isMetric ? 'kg' : 'lbs';

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
                                  calculatorNotifier.weight =
                                      double.tryParse(value) ?? 0.0;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  final weight = double.parse(value);
                                  if (weight <= 0) {
                                    return 'Weight must be greater than 0';
                                  }
                                  final maxWeight =
                                      isMetric ? 227 : 500; // 500 lbs = ~227 kg
                                  if (weight > maxWeight) {
                                    return 'Weight must be less than $maxWeight $weightUnit';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Height Input
                              if (isMetric)
                                InputField(
                                  label: 'Height (cm)',
                                  hint: 'Enter your height in cm',
                                  keyboardType: TextInputType.number,
                                  controller: _inchesController,
                                  onChanged: (value) {
                                    calculatorNotifier.inches =
                                        int.tryParse(value) ?? 0;
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your height';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    final height = int.parse(value);
                                    if (height <= 0) {
                                      return 'Height must be greater than 0';
                                    }
                                    if (height > 250) {
                                      return 'Height must be less than 250 cm';
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
                                          calculatorNotifier.feet =
                                              int.tryParse(value) ?? 0;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter feet';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Invalid number';
                                          }
                                          final feet = int.parse(value);
                                          if (feet <= 0) {
                                            return 'Must be > 0';
                                          }
                                          if (feet > 8) {
                                            return 'Must be < 9';
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
                                          calculatorNotifier.inches =
                                              int.tryParse(value) ?? 0;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter inches';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Invalid number';
                                          }
                                          final inches = int.parse(value);
                                          if (inches < 0) {
                                            return 'Must be >= 0';
                                          }
                                          if (inches > 11) {
                                            return 'Must be < 12';
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
                                  calculatorNotifier.age =
                                      int.tryParse(value) ?? 0;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your age';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  final age = int.parse(value);
                                  if (age <= 0) {
                                    return 'Age must be greater than 0';
                                  }
                                  if (age > 120) {
                                    return 'Age must be less than 120';
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
                                    calculatorNotifier.sex = value;
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
                                    calculatorNotifier.activityLevel =
                                        value.name;
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
                                    calculatorNotifier.goal = value.name;
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
                                    calculatorNotifier.weightChangeRate =
                                        double.tryParse(value); // Allow null
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
                                    String goal = calculatorNotifier.goal;
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
                            if (_formKey.currentState!.validate()) {
                              // Reset weight change rate if goal is maintain
                              if (calculatorNotifier.goal == 'maintain') {
                                calculatorNotifier.weightChangeRate = null;
                              }

                              // Calculate macros and navigate to results
                              final result =
                                  ref
                                      .read(calculatorProvider.notifier)
                                      .calculateMacros();
                              if (result != null) {
                                context.push('/result', extra: result);
                              }
                            }
                          },
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calculate Macros'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              _showCalculationInfoDialog(context);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'How are macros calculated?',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  // Load default macro values if available
  Future<void> _loadDefaultMacroValues() async {
    try {
      final calculator = ref.read(calculatorProvider.notifier);
      final profileRepository = ref.read(profileRepositoryProvider);
      final defaultMacro = await profileRepository.getDefaultMacro();

      if (defaultMacro != null && mounted) {
        // Attempt to reverse-engineer the calculator inputs from the macro result
        // This is an approximation and may not be exact

        // Get user info from the default macro
        final userInfoState = ref.read(userInfoProvider);
        final userInfoNotifier = ref.read(userInfoProvider.notifier);
        final defaultUserInfo = await userInfoNotifier.getDefaultUserInfo();

        if (defaultUserInfo != null) {
          // Set text controllers
          if (defaultUserInfo.weight != null) {
            _weightController.text = defaultUserInfo.weight!.toString();
            calculator.weight = defaultUserInfo.weight!;
          }

          if (defaultUserInfo.feet != null) {
            _feetController.text = defaultUserInfo.feet!.toString();
            calculator.feet = defaultUserInfo.feet!;
          }

          if (defaultUserInfo.inches != null) {
            _inchesController.text = defaultUserInfo.inches!.toString();
            calculator.inches = defaultUserInfo.inches!;
          }

          if (defaultUserInfo.age != null) {
            _ageController.text = defaultUserInfo.age!.toString();
            calculator.age = defaultUserInfo.age!;
          }

          // Set dropdowns
          _selectedSex = defaultUserInfo.sex;
          calculator.sex = defaultUserInfo.sex;

          _selectedActivityLevel = defaultUserInfo.activityLevel;
          calculator.activityLevel = defaultUserInfo.activityLevel.name;

          // Set goal from user info
          _selectedGoal = defaultUserInfo.goal;
          calculator.goal = defaultUserInfo.goal.name;

          // For debugging
          debugPrint('User goal: ${defaultUserInfo.goal.name}');

          _defaultMacroLoaded = true;
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading default macro: $e');
    }
  }
}
