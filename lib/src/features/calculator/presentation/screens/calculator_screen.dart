import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field.dart';

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
    // Load the goal from persistence when the screen initializes
    // Use future.microtask or addPostFrameCallback to ensure ref is available
    Future.microtask(() => ref.read(calculatorProvider.notifier).loadGoal());
  }

  @override
  Widget build(BuildContext context) {
    final calculatorNotifier = ref.watch(calculatorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                            label: 'Weight (lbs):',
                            hint: 'Enter your weight in pounds',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              // Directly update the mutable field in the notifier
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
                              if (double.parse(value) <= 0) {
                                return 'Weight must be greater than 0';
                              }
                              if (double.parse(value) > 500) {
                                return 'Weight must be less than 500';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Height Input
                          const Text('Height:', style: TextStyle(fontSize: 16)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Feet',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.number,
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
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'e.g., 5',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Inches',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.number,
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
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'e.g., 10',
                                      ),
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
                          // Sex Input (Dropdown)
                          const Text('Sex:', style: TextStyle(fontSize: 16)),
                          DropdownButtonFormField<String>(
                            value: calculatorNotifier.sex, // Read current value
                            onChanged: (value) {
                              if (value != null) {
                                // Update the mutable field
                                calculatorNotifier.sex = value;
                                // Manually trigger rebuild if necessary, or use immutable state
                                setState(() {});
                              }
                            },
                            items:
                                [
                                  'male',
                                  'female',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your sex';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Select your sex',
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Activity Level Input (Dropdown)
                          const Text(
                            'Activity Level:',
                            style: TextStyle(fontSize: 16),
                          ),
                          DropdownButtonFormField<String>(
                            value:
                                calculatorNotifier
                                    .activityLevel, // Read current value
                            onChanged: (value) {
                              if (value != null) {
                                calculatorNotifier.activityLevel = value;
                                setState(() {}); // Trigger rebuild
                              }
                            },
                            items:
                                [
                                  'sedentary',
                                  'lightly active',
                                  'moderately active',
                                  'very active',
                                  'extra active',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please select an activity level";
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Select your activity level',
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Goal Input (Radio Buttons)
                          const Text('Goal:', style: TextStyle(fontSize: 16)),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 0.0,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'lose',
                                    groupValue:
                                        calculatorNotifier
                                            .goal, // Read current value
                                    onChanged: (value) {
                                      if (value != null) {
                                        // Call method to update state and save
                                        ref
                                            .read(calculatorProvider.notifier)
                                            .saveGoal(value);
                                        setState(() {}); // Trigger rebuild
                                      }
                                    },
                                  ),
                                  const Text('Lose Weight'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'maintain',
                                    groupValue:
                                        calculatorNotifier
                                            .goal, // Read current value
                                    onChanged: (value) {
                                      if (value != null) {
                                        ref
                                            .read(calculatorProvider.notifier)
                                            .saveGoal(value);
                                        setState(() {}); // Trigger rebuild
                                      }
                                    },
                                  ),
                                  const Text('Maintain Weight'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'gain',
                                    groupValue:
                                        calculatorNotifier
                                            .goal, // Read current value
                                    onChanged: (value) {
                                      if (value != null) {
                                        ref
                                            .read(calculatorProvider.notifier)
                                            .saveGoal(value);
                                        setState(() {}); // Trigger rebuild
                                      }
                                    },
                                  ),
                                  const Text('Gain Weight'),
                                ],
                              ),
                            ],
                          ),
                          // Conditionally show weight change rate input
                          if (calculatorNotifier.goal == 'lose' ||
                              calculatorNotifier.goal == 'gain') ...[
                            const SizedBox(height: 20),
                            InputField(
                              label: 'Weight Change Rate (lbs/week)',
                              hint: 'Enter rate in lbs/week',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                calculatorNotifier.weightChangeRate =
                                    double.tryParse(value); // Allow null
                              },
                              validator: (value) {
                                // Validator only runs if the field is visible
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
                                if (goal == 'lose' && rate > 2) {
                                  return 'The safe recommended weight loss is up to 2 lbs a week';
                                }
                                if (goal == 'gain' && rate > 1) {
                                  return 'The safe recommended weight gain is up to 1 lb. a week';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Ensure weightChangeRate is null when goal is 'maintain'
                            // This might require calling a method on the notifier if validation depends on it
                            // calculatorNotifier.clearWeightChangeRate(); // Example method needed in notifier
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
}
