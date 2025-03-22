import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'calculator_model.dart'; // Your model class

void main() {
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
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: GlobalKey<FormState>(), // Add a global key for the form
            child: MyForm(),
          ),
        ),
      ),
    );
  }
}

class MyForm extends StatelessWidget {
  const MyForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight Input
        Text('Weight (lbs):'),
        TextFormField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            Provider.of<CalculatorModel>(context, listen: false).weight =
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
            return null;
          },
        ),
        SizedBox(height: 20),

       // Height Input
        Text('Height:'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Feet'),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Store the feet value temporarily
                      Provider.of<CalculatorModel>(context, listen: false)
                          .setFeet(int.tryParse(value) ?? 0);
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
                ],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inches'),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      Provider.of<CalculatorModel>(context, listen: false)
                          .setInches(int.tryParse(value) ?? 0);
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
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Age Input
        Text('Age (years):'),
        TextFormField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            Provider.of<CalculatorModel>(context, listen: false).age =
                int.tryParse(value) ?? 0;
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
            return null;
          },
        ),
        SizedBox(height: 20),

        // Sex Input (Dropdown)
        Text('Sex:'),
        DropdownButtonFormField<String>(
          value: Provider.of<CalculatorModel>(context).sex,
          onChanged: (value) {
            Provider.of<CalculatorModel>(context, listen: false).sex = value!;
          },
          items: ['male', 'female'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
           validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your sex';
            }
            return null; // Return null if valid
          },
        ),
        SizedBox(height: 20),

        // Activity Level Input (Dropdown)
        Text('Activity Level:'),
        DropdownButtonFormField<String>(
          value: Provider.of<CalculatorModel>(context).activityLevel,
          onChanged: (value) {
            Provider.of<CalculatorModel>(context, listen: false).activityLevel =
                value!;
          },
          items: [
            'sedentary',
            'lightly active',
            'moderately active',
            'very active',
            'extra active'
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
          }
        ),
        SizedBox(height: 20),

        // Goal Input (Radio Buttons)
        Text('Goal:'),
        Row(
          children: [
            Radio<String>(
              value: 'lose',
              groupValue: Provider.of<CalculatorModel>(context).goal,
              onChanged: (value) {
                Provider.of<CalculatorModel>(context, listen: false).goal = value!;
              },
            ),
            Text('Lose Weight'),
            Radio<String>(
              value: 'maintain',
              groupValue: Provider.of<CalculatorModel>(context).goal,
              onChanged: (value) {
                Provider.of<CalculatorModel>(context, listen: false).goal = value!;
              },
            ),
            Text('Maintain Weight'),
            Radio<String>(
              value: 'gain',
              groupValue: Provider.of<CalculatorModel>(context).goal,
              onChanged: (value) {
                Provider.of<CalculatorModel>(context, listen: false).goal = value!;
              },
            ),
            Text('Gain Weight'),
          ],
        ),
          if (Provider.of<CalculatorModel>(context).goal != 'maintain') ...[
          SizedBox(height: 20),
          //Weight change input
          Text('Weight Change Rate (lbs/week)'),
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
              return null;
            },
          )
        ],
        SizedBox(height: 20),



        // Calculate Button
        ElevatedButton(
          onPressed: () {
              //Wrap in a form widget
              if (Form.of(context).validate()) {
              Provider.of<CalculatorModel>(context, listen: false)
                  .calculateMacros();
              }
          },
          child: Text('Calculate'),
        ),
        SizedBox(height: 20),

        // Result Display
        Text('Calories: ${Provider.of<CalculatorModel>(context).calories.round()}'),
        Text('Protein: ${Provider.of<CalculatorModel>(context).protein.round()}'),
        Text('Carbs: ${Provider.of<CalculatorModel>(context).carbs.round()}'),
        Text('Fat: ${Provider.of<CalculatorModel>(context).fat.round()}'),
      ],
    );
  }
}