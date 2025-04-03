import 'package:flutter/material.dart';
import '../../providerss/calculator_provider.dart';

class ResultScreen extends StatelessWidget {
  final MacroResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Macro Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Macro Results
            Text(
              'Calories: ${result.calories.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text('Protein: ${result.protein.toStringAsFixed(0)}g'),
            Text('Carbs: ${result.carbs.toStringAsFixed(0)}g'),
            Text('Fat: ${result.fat.toStringAsFixed(0)}g'),
          ],
        ),
      ),
    );
  }
}