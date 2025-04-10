import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/calculator/domain/entities/macro_result.dart';
import '../../features/calculator/presentation/screens/result_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_history_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_generator_screen.dart';
import '../../features/meal_plan/presentation/screens/meal_plan_result_screen.dart';
import '../../features/meal_plan/models/meal_plan.dart';
import '../../features/profile/domain/entities/user_info.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

final appRouter = GoRouter(
  debugLogDiagnostics: true, // Enable logging for debugging
  initialLocation: '/signin', // Set initial route to sign-in page
  redirect: (context, state) {
    // Get the current auth state
    final authState = ProviderScope.containerOf(
      context,
    ).read(authStateChangesProvider);

    return authState.when(
      data: (user) {
        // If user is authenticated and trying to access the sign-in page,
        // redirect to the home page
        if (user != null && state.uri.path == '/signin') {
          return '/';
        }

        // If user is not authenticated and not on sign-in page,
        // redirect to sign-in
        if (user == null && state.uri.path != '/signin') {
          return '/signin';
        }

        // No redirection needed
        return null;
      },
      loading: () => null, // Don't redirect while loading
      error: (_, __) => '/signin', // Redirect to sign-in on error
    );
  },
  routes: [
    // Auth Routes - Outside the ShellRoute so they don't have the bottom navigation bar
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    // Main App Routes - Inside ShellRoute to have the bottom navigation bar
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
