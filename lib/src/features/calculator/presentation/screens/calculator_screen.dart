import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field.dart';
import '../../../profile/presentation/providers/settings_provider.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Initialize calculator with default settings
      final settings = ref.read(settingsProvider);
      final calculator = ref.read(calculatorProvider.notifier);
      calculator.goal = settings.goal.name;
      calculator.activityLevel = settings.activityLevel.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calculatorNotifier = ref.watch(calculatorProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isMetric = settings.units == Units.metric;
    final String weightUnit = isMetric ? 'kg' : 'lbs';
    final String heightUnit = isMetric ? 'cm' : 'ft/in';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Macro Calculator'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          // Weight Input
                          InputField(
                            label: 'Weight ($weightUnit):',
                            hint: 'Enter your weight in $weightUnit',
                            keyboardType: TextInputType.number,
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
                          const SizedBox(height: 20),
                          // Height Input
                          Text(
                            'Height ($heightUnit):',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (isMetric)
                            InputField(
                              label: 'Enter your height in centimeters',
                              hint: 'Enter your height in centimeters',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final cm = double.tryParse(value) ?? 0;
                                calculatorNotifier.feet = (cm / 30.48).floor();
                                calculatorNotifier.inches =
                                    ((cm % 30.48) / 2.54).round();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your height';
                                }
                                final height = double.tryParse(value);
                                if (height == null) {
                                  return 'Please enter a valid number';
                                }
                                if (height < 100 || height > 250) {
                                  return 'Please enter a height between 100 and 250 cm';
                                }
                                return null;
                              },
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InputField(
                                        label: 'Feet:',
                                        hint: 'ft',
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          calculatorNotifier.feet =
                                              int.tryParse(value) ?? 0;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          final feet = int.tryParse(value);
                                          if (feet == null ||
                                              feet < 4 ||
                                              feet > 7) {
                                            return 'Enter 4-7';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InputField(
                                        label: 'Inches:',
                                        hint: 'in',
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          calculatorNotifier.inches =
                                              int.tryParse(value) ?? 0;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          final inches = int.tryParse(value);
                                          if (inches == null ||
                                              inches < 0 ||
                                              inches > 11) {
                                            return 'Enter 0-11';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          // Age Input
                          InputField(
                            label: 'Age (years):',
                            hint: 'Enter your age in years',
                            keyboardType: TextInputType.number,
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
                              if (int.parse(value) <= 0) {
                                return 'Age must be greater than 0';
                              }
                              if (int.parse(value) > 150) {
                                return 'Age must be less than 150';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Sex Selection
                          DropdownButtonFormField<String>(
                            value: ref.watch(calculatorProvider.notifier).sex,
                            decoration: const InputDecoration(
                              labelText: 'Sex',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                calculatorNotifier.sex = value;
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your sex';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Activity Level Input (Dropdown)
                          DropdownButtonFormField<ActivityLevel>(
                            value: ActivityLevel.values.firstWhere(
                              (a) => a.name == calculatorNotifier.activityLevel,
                              orElse: () => ActivityLevel.moderatelyActive,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Activity Level',
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
                                calculatorNotifier.activityLevel = value.name;
                                // Also update settings
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(
                                      CalculationSettings(
                                        activityLevel: value,
                                        goal: settings.goal,
                                        units: settings.units,
                                      ),
                                    );
                              }
                            },
                          ),
                          // Goal Dropdown
                          DropdownButtonFormField<Goal>(
                            value: Goal.values.firstWhere(
                              (g) => g.name == calculatorNotifier.goal,
                              orElse: () => Goal.maintain,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Goal',
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
                                calculatorNotifier.goal = value.name;
                                // Also update settings
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(
                                      CalculationSettings(
                                        activityLevel: settings.activityLevel,
                                        goal: value,
                                        units: settings.units,
                                      ),
                                    );
                              }
                            },
                          ),
                          // Conditionally show weight change rate input
                          if (calculatorNotifier.goal != 'maintain') ...[
                            const SizedBox(height: 20),
                            InputField(
                              label: 'Weight Change Rate ($weightUnit/week)',
                              hint: 'Enter rate in $weightUnit/week',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                calculatorNotifier.weightChangeRate =
                                    double.tryParse(value); // Allow null
                              },
                              validator: (value) {
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
                          const SizedBox(height: 20),
                          // Calculate Button
                          Center(
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
