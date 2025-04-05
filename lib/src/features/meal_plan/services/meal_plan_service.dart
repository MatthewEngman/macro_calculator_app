import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_plan.dart';

class MealPlanService {
  static const String baseUrl =
      //'http://localhost:8000'; // Replace with your actual API endpoint
      'http://10.0.2.2:8000'; // Special Android emulator localhost alias

  Future<MealPlan> generateMealPlan({
    required String diet,
    required String goal,
    required Map<String, int> macros,
    required List<String> ingredients,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-meal-plan/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'diet': diet,
          'goal': goal,
          'macros': macros,
          'ingredients': ingredients,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Create a MealPlan object from the response
        return MealPlan(
          diet: diet,
          goal: goal,
          macros: macros,
          ingredients: ingredients,
          plan: responseData['response'] as String,
          feedback: '',
        );
      } else {
        throw Exception('Failed to generate meal plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating meal plan: $e');
    }
  }
}
