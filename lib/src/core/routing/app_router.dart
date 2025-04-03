import 'package:go_router/go_router.dart';
import '../../features/calculator/domain/entities/macro_result.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/calculator/presentation/screens/result_screen.dart';


final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CalculatorScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        // Extract the MacroResult from the state
        final result = state.extra as MacroResult;
        return ResultScreen(result: result);
      }
    )
    // Add more routes for other screens as needed
  ],
);