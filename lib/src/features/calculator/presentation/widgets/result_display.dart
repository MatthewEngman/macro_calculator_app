import 'package:flutter/material.dart';
import '../../domain/entities/macro_result.dart';

class ResultDisplay extends StatelessWidget {
  final MacroResult result;

  const ResultDisplay({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // This widget now just displays the data.
    // Consider showing it inline or triggering a dialog from the screen.
    // Example inline display:
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculation Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Calories: ${result.calories.round()}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Protein: ${result.protein.round()}g',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Carbs: ${result.carbs.round()}g',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Fat: ${result.fat.round()}g',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );

    // --- OR If you want to keep the Dialog behavior ---
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: const Text('Calculation Results'),
    //       content: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Text('Calories: ${result.calories.round()}', style: const TextStyle(fontSize: 18)),
    //           Text('Protein: ${result.protein.round()}g', style: const TextStyle(fontSize: 18)),
    //           Text('Carbs: ${result.carbs.round()}g', style: const TextStyle(fontSize: 18)),
    //           Text('Fat: ${result.fat.round()}g', style: const TextStyle(fontSize: 18)),
    //         ],
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: const Text('OK'),
    //         ),
    //       ],
    //     ),
    //   );
    // });
    // return const SizedBox.shrink(); // Return empty widget if dialog is shown post-frame
  }
}