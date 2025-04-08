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
  final _ageController = TextEditingController();
  String _selectedSex = 'male';
  ActivityLevel _selectedActivityLevel = ActivityLevel.sedentary;
  Goal _selectedGoal = Goal.maintain;

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
        // Use default settings
        calculator.goal = settings.goal.name;
        calculator.activityLevel = settings.activityLevel.name;
        _selectedGoal = settings.goal;
        _selectedActivityLevel = settings.activityLevel;
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
      appBar: AppBar(
        title: const Text('Macro Calculator'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Basic Information Card
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
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
                              calculatorNotifier.age = int.tryParse(value) ?? 0;
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
                ),
                const SizedBox(height: 16),
                // Activity Level Card
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
                          'Activity Level',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
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
                                  child: Text(_getActivityLevelLabel(level)),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedActivityLevel = value;
                              });
                              calculatorNotifier.activityLevel = value.name;
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
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goal',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
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
                            label: 'Weight Change Rate ($weightUnit/week)',
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
                const SizedBox(height: 16),
              ],
            ),
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
}
