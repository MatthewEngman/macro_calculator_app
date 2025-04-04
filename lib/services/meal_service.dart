import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> fetchMealPlan({
  required String diet,
  required String goal,
  required Map<String, dynamic> macros,
  required List<String> ingredients,
}) async {
  final response = await http.post(
    Uri.parse(
      'http://localhost:8000/generate-meal-plan/',
    ), // Change to your LAN IP if testing on a device
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'diet': diet,
      'goal': goal,
      'macros': macros,
      'ingredients': ingredients,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(
      response.body,
    )['response']; // Adjust based on Gemma format
  } else {
    throw Exception('Failed to generate meal plan');
  }
}
