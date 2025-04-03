import 'package:go_router/go_router.dart';
import '../../features/calculator/domain/entities/macro_result.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/calculator/presentation/screens/result_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
          builder: (context, state) => const CalculatorScreen(),
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
      ],
    ),
  ],
);
