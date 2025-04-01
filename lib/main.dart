import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'calculator_model.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Delay for 2 seconds before removing splash screen
  Future.delayed(const Duration(seconds: 2), () {
    FlutterNativeSplash.remove();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => CalculatorModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Masher',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Consistent with Material Design
        fontFamily: 'Roboto', // A popular Material Design font
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded borders
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior:
              FloatingLabelBehavior.always, // Ensure label is always visible
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 12.0,
          ), // Label color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            backgroundColor: Colors.indigo, // Primary button color
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(
            Colors.indigo,
          ), // Active radio color
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(fontSize: 16),
        ),
      ),
      home: const MacroCalculatorForm(), // Renamed for clarity
    );
  }
}

class MacroCalculatorForm extends StatefulWidget {
  const MacroCalculatorForm({super.key});

  @override
  MacroCalculatorFormState createState() => MacroCalculatorFormState();
}

class MacroCalculatorFormState extends State<MacroCalculatorForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Macro Masher'), centerTitle: true),
      body: Container(
          decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/foodbackground.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        constraints: const BoxConstraints.expand(),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ), // Limit max width for larger screens
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                // Make the form scrollable
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Weight Input
                    const Text('Weight (lbs):', style: TextStyle(fontSize: 16)),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        Provider.of<CalculatorModel>(context, listen: false)
                            .weight = double.tryParse(value) ?? 0.0;
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
                      decoration: const InputDecoration(
                        //labelText: 'Your Weight',
                        hintText: 'Enter your weight in pounds',
                      ),
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
                                  Provider.of<CalculatorModel>(
                                    context,
                                    listen: false,
                                  ).setFeet(int.tryParse(value) ?? 0);
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
                                  Provider.of<CalculatorModel>(
                                    context,
                                    listen: false,
                                  ).setInches(int.tryParse(value) ?? 0);
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
                    const Text('Age (years):', style: TextStyle(fontSize: 16)),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        Provider.of<CalculatorModel>(context, listen: false)
                            .age = int.tryParse(value) ?? 0;
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
                      decoration: const InputDecoration(
                        //labelText: 'Your Age',
                        hintText: 'Enter your age in years',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sex Input (Dropdown)
                    const Text('Sex:', style: TextStyle(fontSize: 16)),
                    DropdownButtonFormField<String>(
                      value: Provider.of<CalculatorModel>(context).sex,
                      onChanged: (value) {
                        Provider.of<CalculatorModel>(context, listen: false)
                            .sex = value!;
                      },
                      items:
                          ['male', 'female'].map<DropdownMenuItem<String>>((
                            String value,
                          ) {
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
                        //labelText: 'Sex',
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
                          Provider.of<CalculatorModel>(context).activityLevel,
                      onChanged: (value) {
                        Provider.of<CalculatorModel>(context, listen: false)
                            .activityLevel = value!;
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
                        //labelText: 'Activity Level',
                        hintText: 'Select your activity level',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Goal Input (Radio Buttons)
                    const Text('Goal:', style: TextStyle(fontSize: 16)),
                    Wrap(
                      spacing: 8.0, // Gap between adjacent chips
                      runSpacing: 0.0, // Gap between lines
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'lose',
                              groupValue:
                                  Provider.of<CalculatorModel>(context).goal,
                              onChanged: (value) {
                                Provider.of<CalculatorModel>(
                                      context,
                                      listen: false,
                                    ).goal =
                                    value!;
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
                                  Provider.of<CalculatorModel>(context).goal,
                              onChanged: (value) {
                                Provider.of<CalculatorModel>(
                                      context,
                                      listen: false,
                                    ).goal =
                                    value!;
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
                                  Provider.of<CalculatorModel>(context).goal,
                              onChanged: (value) {
                                Provider.of<CalculatorModel>(
                                      context,
                                      listen: false,
                                    ).goal =
                                    value!;
                              },
                            ),
                            const Text('Gain Weight'),
                          ],
                        ),
                      ],
                    ),
                    if (Provider.of<CalculatorModel>(context).goal == 'lose' ||
                        Provider.of<CalculatorModel>(context).goal ==
                            'gain') ...[
                      const SizedBox(height: 20),
                      //Weight change input
                      const Text(
                        'Weight Change Rate (lbs/week)',
                        style: TextStyle(fontSize: 16),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          Provider.of<CalculatorModel>(context, listen: false)
                              .weightChangeRate = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a rate.';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Rate must be greater than 0';
                          }
                          double rate = double.parse(value);
                          String goal =
                              Provider.of<CalculatorModel>(
                                context,
                                listen: false,
                              ).goal;

                          if (goal == 'lose' && rate > 2) {
                            return 'The safe recommended weight loss is up to 2 lbs a week';
                          }
                          if (goal == 'gain' && rate > 1) {
                            return 'The safe recommended weight gain is up to 1 lb. a week';
                          }

                          return null;
                        },
                        decoration: const InputDecoration(
                          //labelText: 'Weight Change Rate',
                          hintText: 'Enter rate in lbs/week',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Calculate Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Use the form key
                            Provider.of<CalculatorModel>(
                              context,
                              listen: false,
                            ).calculateMacros();
                            // Show a dialog with the results
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Calculation Results'),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Calories: ${Provider.of<CalculatorModel>(context).calories.round()}',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        'Protein: ${Provider.of<CalculatorModel>(context).protein.round()}g',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        'Carbs: ${Provider.of<CalculatorModel>(context).carbs.round()}g',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        'Fat: ${Provider.of<CalculatorModel>(context).fat.round()}g',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: const Text('Mash Macros'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
