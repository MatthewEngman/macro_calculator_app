import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meal_plan.dart';

class MealPlanService {
  // API URL configuration based on environment
  static String get baseUrl {
    // For production or real device use
    if (kReleaseMode) {
      // Replace with your production API URL
      return 'https://your-production-api.com';
    }

    // For development use
    if (Platform.isAndroid) {
      // Android emulator needs this special IP
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8000';
    } else {
      // Default fallback
      return 'http://localhost:8000';
    }
  }

  // Add a method to check if the API is available
  Future<bool> isApiAvailable() async {
    try {
      // Try to access the generate-meal-plan endpoint directly with a HEAD request
      final response = await http
          .head(Uri.parse('$baseUrl/generate-meal-plan/'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode <
          500; // Any response except server error indicates API is up
    } catch (e) {
      return false; // Any exception means API is not available
    }
  }

  Future<MealPlan> generateMealPlan({
    required String diet,
    required String goal,
    required Map<String, int> macros,
    required List<String> ingredients,
  }) async {
    try {
      // First check if API is available
      final isAvailable = await isApiAvailable();
      if (!isAvailable) {
        throw const ApiUnavailableException(
          'Meal plan generation service is currently unavailable',
        );
      }

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
    } on ApiUnavailableException {
      rethrow;
    } catch (e) {
      throw Exception('Error generating meal plan: $e');
    }
  }
}

// Custom exception for API unavailability
class ApiUnavailableException implements Exception {
  final String message;

  const ApiUnavailableException(this.message);

  @override
  String toString() => message;
}
