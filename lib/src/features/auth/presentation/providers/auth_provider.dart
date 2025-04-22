import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart';
import 'package:macro_masher/src/core/persistence/shared_preferences_provider.dart';
import 'package:macro_masher/src/core/routing/app_router.dart';
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/calculator/domain/entities/macro_result.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/profile_provider.dart';
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
        print('Auth state listener: Google user detected: ${user.uid}');
        // When a user signs in, check if they need onboarding
        final prefs = ref.read(sharedPreferencesProvider);
        final onboardingComplete =
            prefs.getBool('onboarding_complete_${user.uid}') ??
            prefs.getBool('onboarding_complete') ??
            false;

        print('Auth state listener: Onboarding complete: $onboardingComplete');

        if (!onboardingComplete) {
          // User needs onboarding, navigate to onboarding screen
          print(
            'Auth state listener: Navigating to onboarding for Google user',
          );
          // Use a longer delay to ensure the app is fully initialized
          Future.delayed(Duration(milliseconds: 500), () {
            try {
              ref.read(navigationProvider)('/onboarding');
              print('Auth state listener: Navigation to onboarding triggered');
            } catch (e) {
              print('Auth state listener: Error navigating to onboarding: $e');
            }
          });
          return;
        }

        // Otherwise, check if they have a profile and create one if needed
        try {
          print('Auth state listener: Checking for user profile');
          final syncService = await ref.read(
            firestoreSyncServiceProvider.future,
          );
          final userInfos = await syncService.getSavedUserInfos(user.uid);

          if (userInfos.isEmpty) {
            // No user profile found, this is likely a new Google sign-in
            // Redirect to onboarding instead of creating a default profile
            print(
              'Auth state listener: No profile found, navigating to onboarding',
            );
            Future.delayed(Duration(milliseconds: 500), () {
              try {
                ref.read(navigationProvider)('/onboarding');
                print(
                  'Auth state listener: Navigation to onboarding triggered (no profile)',
                );
              } catch (e) {
                print(
                  'Auth state listener: Error navigating to onboarding: $e',
                );
              }
            });
            return;
          } else {
            print(
              'Auth state listener: User profile found, navigating to dashboard',
            );
            // User has a profile, navigate to dashboard
            Future.delayed(Duration(milliseconds: 500), () {
              try {
                ref.read(navigationProvider)('/');
                print('Auth state listener: Navigation to dashboard triggered');
              } catch (e) {
                print('Auth state listener: Error navigating to dashboard: $e');
              }
            });
          }
        } catch (e, stack) {
          print(
            'Error checking/creating user profile in auth listener: $e\n$stack',
          );
          // Handle error by still navigating to onboarding
          print(
            'Auth state listener: Error checking profile, navigating to onboarding',
          );
          Future.delayed(Duration(milliseconds: 500), () {
            try {
              ref.read(navigationProvider)('/onboarding');
              print(
                'Auth state listener: Navigation to onboarding triggered (error case)',
              );
            } catch (e) {
              print('Auth state listener: Error navigating to onboarding: $e');
            }
          });
        }
      } else if (user != null && user.isAnonymous) {
        // Anonymous user, show onboarding
        print(
          'Auth state listener: Anonymous user detected, navigating to onboarding',
        );
        Future.delayed(Duration(milliseconds: 500), () {
          try {
            ref.read(navigationProvider)('/onboarding');
            print(
              'Auth state listener: Navigation to onboarding triggered (anonymous)',
            );
          } catch (e) {
            print('Auth state listener: Error navigating to onboarding: $e');
          }
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

  if (oldUserId.isEmpty || newUserId.isEmpty) {
    print(
      'Invalid user IDs for migration: oldUserId=$oldUserId, newUserId=$newUserId',
    );
    return;
  }

  try {
    // 1. Get all the data from the old user
    final syncService = await ref.read(firestoreSyncServiceProvider.future);
    final profileRepository = await ref.read(
      profileRepositorySyncProvider.future,
    );

    // 2. Get user profiles
    final userInfos = await syncService.getSavedUserInfos(oldUserId);
    print('Found ${userInfos.length} user profiles to migrate');

    // 3. Migrate macro calculations
    String? defaultCalculationId;
    bool defaultMigrated = false;

    try {
      // First, clear any existing default calculations for the new user
      // to prevent duplicates
      final macroCalculationDB = MacroCalculationDB();
      await macroCalculationDB.executeWithRecovery(
        (db) => db.update(
          'macro_calculations',
          {'is_default': 0},
          where: 'user_id = ?',
          whereArgs: [newUserId],
        ),
      );

      // Get all calculations for the old user
      final calculations = await macroCalculationDB.getAllCalculations(
        userId: oldUserId,
      );
      print('Found ${calculations.length} macro calculations to migrate');

      // Track which calculations have been migrated to avoid duplicates
      final Set<String> migratedIds = {};

      for (final calculation in calculations) {
        try {
          // Skip if we've already migrated this calculation
          if (calculation.id == null ||
              calculation.id!.isEmpty ||
              migratedIds.contains(calculation.id)) {
            continue;
          }

          // Update the userId and preserve other properties
          final updatedCalculation = calculation.copyWith(
            userId: newUserId,
            // Don't set isDefault here - we'll handle that separately
            isDefault: false,
          );

          if (updatedCalculation.id != null &&
              updatedCalculation.id!.isNotEmpty) {
            await macroCalculationDB.insertCalculation(
              updatedCalculation,
              newUserId,
            );
            migratedIds.add(calculation.id!);
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
    final Set<String> migratedProfileIds = {};

    for (final userInfo in userInfos) {
      try {
        // Skip if we've already migrated this profile
        if (userInfo.id == null ||
            userInfo.id!.isEmpty ||
            migratedProfileIds.contains(userInfo.id)) {
          continue;
        }

        await syncService.saveUserInfo(newUserId, userInfo);
        migratedProfileIds.add(userInfo.id!);
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

            // First, clear any existing defaults
            await macroCalculationDB.executeWithRecovery(
              (db) => db.update(
                'macro_calculations',
                {'is_default': 0},
                where: 'user_id = ?',
                whereArgs: [newUserId],
              ),
            );

            // Then save the new default
            await macroCalculationDB.insertCalculation(
              macroResult.copyWith(isDefault: true),
              newUserId,
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

    // 7. Force refresh profile provider to update UI
    ref.invalidate(profileProvider);

    print('Data migration completed successfully');
  } catch (e, stack) {
    print('Error during account linking data migration: $e\n$stack');
  }
}
