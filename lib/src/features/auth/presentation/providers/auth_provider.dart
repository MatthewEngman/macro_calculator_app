import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macro_masher/src/core/routing/app_router.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../profile/domain/entities/user_info.dart' as app;
import '../../../profile/presentation/providers/user_info_provider.dart';
import '../../../profile/presentation/providers/settings_provider.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepositoryImpl(firebaseAuth);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final navigationProvider = Provider<void Function(String)>((ref) {
  return (String route) {
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go(route);
    }
  };
});

final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, current) {
    current.whenData((user) {
      if (user != null) {
        // When a user signs in, check if they need onboarding
        final prefs = ref.read(sharedPreferencesProvider);
        final onboardingComplete =
            prefs.getBool('onboarding_complete') ?? false;

        if (!onboardingComplete) {
          // User needs onboarding, navigate to onboarding screen
          Future.delayed(Duration(milliseconds: 100), () {
            ref.read(navigationProvider)('/onboarding');
          });
          return;
        }

        // Otherwise, check if they have a profile and create one if needed
        final userInfoNotifier = ref.read(userInfoProvider.notifier);
        userInfoNotifier.loadSavedUserInfos().then((userInfos) {
          if (userInfos.isEmpty) {
            // Create a default profile for the new user
            final defaultProfile = app.UserInfo(
              weight: 70,
              feet: 5,
              inches: 10,
              age: 30,
              sex: 'male',
              activityLevel: ActivityLevel.moderatelyActive,
              goal: Goal.maintain,
              units: Units.imperial,
            );
            userInfoNotifier.saveUserInfo(defaultProfile);
          }
        });
      }
    });
  });
});
