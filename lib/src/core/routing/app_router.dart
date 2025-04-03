import 'package:go_router/go_router.dart';
// Correct the import path based on your structure
import '../../features/calculator/presentation/screens/calculator_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CalculatorScreen(),
    ),
    // Add more routes for other screens as needed
  ],
);