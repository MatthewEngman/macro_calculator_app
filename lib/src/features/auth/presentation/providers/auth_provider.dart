import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Add a provider that listens to auth state changes and creates a default profile if needed
final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, current) {
    current.whenData((user) {
      if (user != null) {
        // When a user signs in (including anonymously), check if they have a profile
        // and create one if they don't
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
