import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart';
import 'package:macro_masher/src/core/persistence/shared_preferences_provider.dart';
import 'package:macro_masher/src/core/routing/app_router.dart';
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/calculator/domain/entities/macro_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../profile/domain/entities/user_info.dart' as app;
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
  // Keep track of the previous user state for account linking detection
  User? previousUser;

  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, current) {
    current.whenData((user) async {
      // Check for account linking (anonymous to authenticated)
      if (previousUser != null &&
          previousUser!.isAnonymous &&
          user != null &&
          !user.isAnonymous &&
          previousUser!.uid != user.uid) {
        // User has linked their anonymous account to a Google account with a different UID
        print('Account linking detected: ${previousUser!.uid} -> ${user.uid}');
        await _migrateUserData(ref, previousUser!.uid, user.uid);
      }

      // Update previous user for next comparison
      previousUser = user;

      if (user != null && !user.isAnonymous) {
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
        final syncService = await ref.read(firestoreSyncServiceProvider.future);

        try {
          final userInfos = await syncService.getSavedUserInfos(user.uid);
          if (userInfos.isEmpty) {
            // No user profile found, this is likely a new Google sign-in
            // Redirect to onboarding instead of creating a default profile
            Future.delayed(Duration(milliseconds: 100), () {
              ref.read(navigationProvider)('/onboarding');
            });
            return;
          }
        } catch (e, stack) {
          print(
            'Error checking/creating user profile in auth listener: $e\n$stack',
          );
          // Handle error appropriately, maybe log it
        }
      } else if (user != null && user.isAnonymous) {
        // Anonymous user, show onboarding
        Future.delayed(Duration(milliseconds: 100), () {
          ref.read(navigationProvider)('/onboarding');
        });
      }
    });
  });
});

/// Migrates user data from an anonymous account to a linked Google account
Future<void> _migrateUserData(
  Ref ref,
  String oldUserId,
  String newUserId,
) async {
  print('Starting data migration from $oldUserId to $newUserId');

  try {
    // 1. Get the repositories we need
    final syncService = await ref.read(firestoreSyncServiceProvider.future);
    final profileRepository = await ref.read(
      profileRepositorySyncProvider.future,
    );

    // Track if we successfully migrated a default calculation
    bool defaultMigrated = false;
    String? defaultCalculationId;

    // 2. Get all user data from the old user ID
    final userInfos = await syncService.getSavedUserInfos(oldUserId);
    print('Found ${userInfos.length} user profiles to migrate');

    // 3. Get all macro calculations for the old user ID
    // Use the hybrid storage approach that handles database read-only issues
    try {
      final macroCalculationDB = MacroCalculationDB();
      final calculations = await macroCalculationDB.getAllCalculations(
        userId: oldUserId,
      );
      print('Found ${calculations.length} macro calculations to migrate');

      // 5. Migrate macro calculations
      for (final calculation in calculations) {
        try {
          // Create a copy with the new user ID
          final updatedCalculation = calculation.copyWith(userId: newUserId);

          // Check for valid ID before inserting
          if (updatedCalculation.id != null &&
              updatedCalculation.id!.isNotEmpty) {
            await macroCalculationDB.insertCalculation(
              updatedCalculation,
              userId: newUserId,
            );
            print('Migrated macro calculation: ${calculation.id}');

            // If this was the default calculation, track it for setting later
            if (calculation.isDefault) {
              defaultCalculationId = calculation.id;
              print('Found default calculation ${calculation.id} to migrate');
            }
          } else {
            print('Skipping calculation with null or empty ID');
          }
        } catch (e) {
          print('Error migrating calculation ${calculation.id}: $e');
          // Continue with next calculation
        }
      }

      // Set the default calculation after all calculations are migrated
      if (defaultCalculationId != null && defaultCalculationId.isNotEmpty) {
        try {
          print(
            'Setting calculation $defaultCalculationId as default for new user',
          );
          await macroCalculationDB.setDefaultCalculation(
            id: defaultCalculationId,
            userId: newUserId,
          );
          defaultMigrated = true;
          print('Successfully set default calculation for new user');
        } catch (e) {
          print('Error setting default calculation: $e');
          // Try alternative approach through profile repository
          try {
            await profileRepository.setDefaultMacro(
              defaultCalculationId,
              userId: newUserId,
            );
            defaultMigrated = true;
            print('Set default calculation using profile repository');
          } catch (e2) {
            print(
              'Failed to set default calculation using alternative method: $e2',
            );
          }
        }
      }
    } catch (e) {
      print('Error accessing macro calculations: $e');
      // Continue with the migration process
    }

    // 4. Migrate user profiles
    for (final userInfo in userInfos) {
      try {
        await syncService.saveUserInfo(newUserId, userInfo);
        print('Migrated user profile: ${userInfo.id}');

        // If we haven't migrated a default calculation yet and this profile is default
        if (!defaultMigrated &&
            userInfo.isDefault &&
            userInfo.id != null &&
            userInfo.id!.isNotEmpty) {
          try {
            // Create a macro result from the user info with the new user ID
            final macroResult = MacroResult.fromUserInfo(
              userInfo,
              explicitUserId: newUserId,
            );

            // Save it to the database
            final macroCalculationDB = MacroCalculationDB();
            await macroCalculationDB.insertCalculation(
              macroResult.copyWith(isDefault: true),
              userId: newUserId,
            );

            defaultMigrated = true;
            print('Created and set default calculation from user profile');
          } catch (e) {
            print('Error creating default calculation from profile: $e');
          }
        }
      } catch (e) {
        print('Error migrating user profile ${userInfo.id}: $e');
        // Continue with next profile
      }
    }

    // 6. Migrate SharedPreferences data
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final oldKey = 'saved_macros_$oldUserId';
      final newKey = 'saved_macros_$newUserId';
      final savedMacrosData = prefs.getString(oldKey);
      if (savedMacrosData != null) {
        await prefs.setString(newKey, savedMacrosData);
        print('Migrated SharedPreferences data');
      }
    } catch (e) {
      print('Error migrating SharedPreferences data: $e');
    }

    print('Data migration completed successfully');
  } catch (e, stack) {
    print('Error during account linking data migration: $e\n$stack');
  }
}
