import 'package:go_router/go_router.dart';
import '../../features/calculator/domain/entities/macro_result.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/calculator/presentation/screens/result_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_generator_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_history_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_result_screen.dart';
import '../../features/meal_plan/models/meal_plan.dart';
import '../../features/profile/domain/entities/user_info.dart';
import '../../shared/widgets/app_scaffold.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final userInfo = state.extra as UserInfo?;
            return CalculatorScreen(userInfo: userInfo);
          },
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final result = state.extra as MacroResult;
            return ResultScreen(result: result);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        // Meal Plan Routes
        GoRoute(
          path: '/meal-plans',
          builder: (context, state) => const MealPlanHistoryScreen(),
        ),
        GoRoute(
          path: '/meal-plans/generate',
          builder: (context, state) => const MealPlanGeneratorScreen(),
        ),
        GoRoute(
          path: '/meal-plans/result',
          builder: (context, state) {
            final mealPlan = state.extra as MealPlan;
            return MealPlanResultScreen(mealPlan: mealPlan);
          },
        ),
      ],
    ),
  ],
);
