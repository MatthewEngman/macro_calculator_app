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
      // Firebase Functions URL - direct URL from deployment
      return 'https://generatemealplan-tf3ipswbia-uc.a.run.app';
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
      if (kReleaseMode) {
        // For Cloud Functions, we'll try the health check endpoint
        final response = await http
            .get(Uri.parse('$baseUrl/healthCheck'))
            .timeout(const Duration(seconds: 5));

        print(
          'Health check response: ${response.statusCode} - ${response.body}',
        );
        return response.statusCode == 200;
      } else {
        // For local development server
        final response = await http
            .get(Uri.parse('$baseUrl/'))
            .timeout(const Duration(seconds: 3));

        return response.statusCode < 500;
      }
    } catch (e) {
      print('API availability check failed: $e');
      return false; // Any exception means API is not available
    }
  }

  Future<MealPlan> generateMealPlan({
    required String userId,
    required String diet,
    required String goal,
    required Map<String, double> macros,
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

      // Prepare the request body
      final requestBody = {
        'diet': diet,
        'goal': goal,
        'macros': {
          'calories': macros['calories'] ?? 0,
          'protein': macros['protein'] ?? 0,
          'carbs': macros['carbs'] ?? 0,
          'fat': macros['fat'] ?? 0,
        },
        'ingredients': ingredients,
      };

      print('Sending request to: $baseUrl');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Create a MealPlan object from the response
        return MealPlan(
          userId: userId,
          totalCalories: (responseData['total_calories'] as num?)?.toDouble(),
          totalProtein: (responseData['total_protein'] as num?)?.toDouble(),
          totalCarbs: (responseData['total_carbs'] as num?)?.toDouble(),
          totalFat: (responseData['total_fat'] as num?)?.toDouble(),
          meals: responseData['meal_details_json'] as String?,
          notes: responseData['notes'] as String?,
          createdAt: DateTime.now(), // Set creation time locally
          // date: Set appropriate date if needed
          // firebaseUserId: Set if available/needed
        );
      } else {
        throw Exception(
          'Failed to generate meal plan: ${response.statusCode} - ${response.body}',
        );
      }
    } on ApiUnavailableException {
      rethrow;
    } catch (e) {
      print('Error generating meal plan: $e');
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
