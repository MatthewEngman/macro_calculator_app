import 'package:flutter/material.dart';
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
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../core/persistence/shared_preferences_provider.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  debugLogDiagnostics: true, // Enable logging for debugging
  initialLocation: '/signin', // Set initial route to sign-in page
  redirect: (context, state) {
    // Get the current auth state and onboarding status
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authStateChangesProvider);

    // Check if onboarding is completed for the current user
    bool isOnboardingCompleted = false;
    String? currentUserId;

    authState.whenData((user) {
      if (user != null) {
        currentUserId = user.uid;
        // Check both user-specific and general onboarding flags
        final prefs = container.read(sharedPreferencesProvider);
        final userSpecificKey = 'onboarding_complete_${user.uid}';
        final generalKey = 'onboarding_complete';

        isOnboardingCompleted =
            prefs.getBool(userSpecificKey) ??
            prefs.getBool(generalKey) ??
            false;

        print(
          'Router: User ${user.uid} onboarding complete: $isOnboardingCompleted',
        );
      }
    });

    // IMPORTANT: Check if we're already on the onboarding screen
    final isOnOnboardingScreen = state.uri.path == '/onboarding';

    return authState.when(
      data: (user) {
        // If user is not authenticated and not on sign-in page,
        // redirect to sign-in
        if (user == null && state.uri.path != '/signin') {
          print('Router: Not authenticated, redirecting to sign-in');
          return '/signin';
        }

        // If user is authenticated
        if (user != null) {
          // If onboarding is not complete and not already on onboarding screen
          if (!isOnboardingCompleted && !isOnOnboardingScreen) {
            print('Router: Redirecting to onboarding (not complete)');
            return '/onboarding';
          }

          // If trying to access sign-in while authenticated and onboarding is complete
          if (state.uri.path == '/signin' && isOnboardingCompleted) {
            print('Router: Already authenticated, redirecting to dashboard');
            return '/';
          }
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
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Main App Routes - Inside ShellRoute to have the bottom navigation bar
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const DashboardScreen(), // Use the new dashboard screen as home
        ),
        GoRoute(
          path: '/calculator',
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
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
      ],
    ),
  ],
);
