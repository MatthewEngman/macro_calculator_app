import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../calculator/domain/entities/macro_result.dart';
import '../../../../core/persistence/onboarding_provider.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as persistence;
import 'package:macro_masher/src/core/persistence/shared_preferences_provider.dart';
import 'dart:convert';

final macroListProvider = FutureProvider<List<MacroResult>>((ref) async {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  if (!onboardingComplete) return [];

  // Get the current user ID from Firebase
  final auth = ref.read(persistence.firebaseAuthProvider);
  final currentUser = auth.currentUser;
  final userId = currentUser?.uid;

  // If no user (not even anonymous), return empty list
  if (userId == null) {
    print(
      'Macro List Provider: No user found (neither signed-in nor anonymous)',
    );
    return [];
  }

  final repository = await ref.watch(
    persistence.profileRepositorySyncProvider.future,
  );

  print(
    'Macro List Provider: Getting macros for user $userId (anonymous: ${currentUser?.isAnonymous})',
  );
  return await repository.getSavedMacros(userId: userId);
});

final defaultMacroProvider = FutureProvider<MacroResult?>((ref) async {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  if (!onboardingComplete) {
    print('Default Macro Provider: Onboarding not complete, returning null');
    return null;
  }

  // Get the current user ID from Firebase
  final auth = ref.read(persistence.firebaseAuthProvider);
  final currentUser = auth.currentUser;
  final userId = currentUser?.uid;

  if (userId == null) {
    print(
      'Default Macro Provider: No user found (neither signed-in nor anonymous)',
    );
    return null;
  }

  print(
    'Default Macro Provider: Getting repository for user $userId (anonymous: ${currentUser?.isAnonymous})...',
  );

  MacroResult? defaultMacro;

  try {
    final repository = await ref.watch(
      persistence.profileRepositorySyncProvider.future,
    );

    print(
      'Default Macro Provider: Retrieving default macro for user $userId...',
    );
    defaultMacro = await repository.getDefaultMacro(userId: userId);

    if (defaultMacro != null) {
      print(
        'Default Macro Provider: Found default macro with ID: ${defaultMacro.id} for user $userId',
      );
      return defaultMacro;
    } else {
      print(
        'Default Macro Provider: No default macro found for user $userId in database',
      );
    }
  } catch (e) {
    print('Default Macro Provider: Error retrieving from repository: $e');
    // Continue to SharedPreferences fallback
  }

  // If we reach here, either the repository failed or returned null
  // Try to get from SharedPreferences directly
  try {
    print(
      'Default Macro Provider: Trying SharedPreferences fallback for user $userId',
    );
    final prefs = ref.read(sharedPreferencesProvider);

    // First try the dedicated default macro key
    final defaultMacroJson = prefs.getString('default_macro_$userId');
    if (defaultMacroJson != null && defaultMacroJson.isNotEmpty) {
      final macroMap = jsonDecode(defaultMacroJson) as Map<String, dynamic>;
      defaultMacro = MacroResult(
        id: macroMap['id'],
        calories: (macroMap['calories'] as num).toDouble(),
        protein: (macroMap['protein'] as num).toDouble(),
        carbs: (macroMap['carbs'] as num).toDouble(),
        fat: (macroMap['fat'] as num).toDouble(),
        calculationType: macroMap['calculationType'],
        timestamp:
            macroMap['timestamp'] != null
                ? DateTime.parse(macroMap['timestamp'])
                : null,
        isDefault: true,
        name: macroMap['name'],
        lastModified:
            macroMap['lastModified'] != null
                ? DateTime.parse(macroMap['lastModified'])
                : null,
        userId: userId,
      );
      print(
        'Default Macro Provider: Found default macro in SharedPreferences dedicated key',
      );
      return defaultMacro;
    }

    // If no dedicated default, try to find in the saved macros list
    final savedMacrosJson = prefs.getString('saved_macros_$userId');
    if (savedMacrosJson != null && savedMacrosJson.isNotEmpty) {
      final macrosList = jsonDecode(savedMacrosJson) as List<dynamic>;

      // First try to find a macro marked as default
      final defaultMacroMap = macrosList
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (macro) => macro['isDefault'] == true,
            orElse: () => <String, dynamic>{},
          );

      if (defaultMacroMap.isNotEmpty) {
        defaultMacro = MacroResult(
          id: defaultMacroMap['id'],
          calories: (defaultMacroMap['calories'] as num).toDouble(),
          protein: (defaultMacroMap['protein'] as num).toDouble(),
          carbs: (defaultMacroMap['carbs'] as num).toDouble(),
          fat: (defaultMacroMap['fat'] as num).toDouble(),
          calculationType: defaultMacroMap['calculationType'],
          timestamp:
              defaultMacroMap['timestamp'] != null
                  ? DateTime.parse(defaultMacroMap['timestamp'])
                  : null,
          isDefault: true,
          name: defaultMacroMap['name'],
          lastModified:
              defaultMacroMap['lastModified'] != null
                  ? DateTime.parse(defaultMacroMap['lastModified'])
                  : null,
          userId: userId,
        );
        print(
          'Default Macro Provider: Found default macro in SharedPreferences saved macros list',
        );
        return defaultMacro;
      }

      // If no default marked, just use the most recent one (last in list)
      if (macrosList.isNotEmpty) {
        final lastMacroMap = macrosList.last as Map<String, dynamic>;
        defaultMacro = MacroResult(
          id: lastMacroMap['id'],
          calories: (lastMacroMap['calories'] as num).toDouble(),
          protein: (lastMacroMap['protein'] as num).toDouble(),
          carbs: (lastMacroMap['carbs'] as num).toDouble(),
          fat: (lastMacroMap['fat'] as num).toDouble(),
          calculationType: lastMacroMap['calculationType'],
          timestamp:
              lastMacroMap['timestamp'] != null
                  ? DateTime.parse(lastMacroMap['timestamp'])
                  : null,
          isDefault: true, // Mark as default even if it wasn't originally
          name: lastMacroMap['name'],
          lastModified:
              lastMacroMap['lastModified'] != null
                  ? DateTime.parse(lastMacroMap['lastModified'])
                  : null,
          userId: userId,
        );
        print(
          'Default Macro Provider: Using last macro from SharedPreferences as default',
        );
        return defaultMacro;
      }
    }

    print('Default Macro Provider: No macro found in SharedPreferences');
  } catch (e) {
    print(
      'Default Macro Provider: Error retrieving from SharedPreferences: $e',
    );
  }

  // If we reach here, we couldn't find a default macro anywhere
  print('Default Macro Provider: No default macro found for user $userId');
  return null;
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<List<MacroResult>>>((
      ref,
    ) {
      return ProfileNotifier(ref);
    });

// final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
//   final syncService = ref.watch(firestoreSyncServiceProvider);
//   return ProfileRepositoryHybridImpl(syncService);
// });

class ProfileNotifier extends StateNotifier<AsyncValue<List<MacroResult>>> {
  final Ref ref;
  late final ProfileRepository _repository;
  bool _isDisposed = false;

  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;
    state = const AsyncValue.loading();
    try {
      _repository = await ref.watch(
        persistence.profileRepositorySyncProvider.future,
      );

      // Get the current user ID
      final auth = ref.read(persistence.firebaseAuthProvider);
      final currentUser = auth.currentUser;
      final userId = currentUser?.uid;

      // Only clean up if we have a user ID
      if (userId != null) {
        // Clean up SharedPreferences data to ensure only one default macro
        await _cleanupSharedPreferencesData(userId);
      }

      await loadSavedMacros();
      final macros = await _repository.getSavedMacros();
      if (!_isDisposed) {
        state = AsyncValue.data(macros);
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // Method to clean up SharedPreferences data to ensure only one default macro
  Future<void> _cleanupSharedPreferencesData(String userId) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // We already have the userId passed as a parameter, so no need to get it again
      if (userId.isEmpty) return;

      final key = 'saved_macros_$userId';
      final defaultKey = 'default_macro_$userId';
      final existingDataStr = prefs.getString(key);

      if (existingDataStr == null || existingDataStr.isEmpty) return;

      // Parse existing data
      final List<dynamic> parsed = jsonDecode(existingDataStr);
      final List<Map<String, dynamic>> macrosList =
          parsed.map((item) => Map<String, dynamic>.from(item)).toList();

      if (macrosList.isEmpty) return;

      // Find the current default macro from our state
      final currentMacros = state.valueOrNull;

      // If we have state data, use it to determine the default
      if (currentMacros != null && currentMacros.isNotEmpty) {
        final defaultMacro = currentMacros.firstWhere(
          (m) => m.isDefault == true,
          orElse: () => currentMacros.first,
        );

        bool dataChanged = false;

        // Update SharedPreferences to match our state
        for (int i = 0; i < macrosList.length; i++) {
          final macro = macrosList[i] as Map<String, dynamic>;
          final id = macro['id'];
          final isCurrentlyDefault = macro['isDefault'] == true;
          final shouldBeDefault = defaultMacro.id == id;

          if (isCurrentlyDefault != shouldBeDefault) {
            macrosList[i]['isDefault'] = shouldBeDefault;
            dataChanged = true;
          }
        }

        // Save updated list if changes were made
        if (dataChanged) {
          await prefs.setString(key, jsonEncode(macrosList));
          print(
            'SharedPreferences data cleaned up: ensured only one default macro',
          );

          // Update the dedicated default macro key
          final defaultMacroJson = jsonEncode({
            'id': defaultMacro.id,
            'calories': defaultMacro.calories,
            'protein': defaultMacro.protein,
            'carbs': defaultMacro.carbs,
            'fat': defaultMacro.fat,
            'timestamp': defaultMacro.timestamp?.toIso8601String(),
            'isDefault': true,
            'userId': defaultMacro.userId,
            'name': defaultMacro.name,
            'calculationType': defaultMacro.calculationType,
            'lastModified': defaultMacro.lastModified?.toIso8601String(),
          });
          await prefs.setString(defaultKey, defaultMacroJson);
        }
      } else {
        // If we don't have state data, find the most recent default in SharedPreferences
        Map<String, dynamic>? mostRecentDefault;
        DateTime? mostRecentTime;

        for (final macro in macrosList) {
          if (macro['isDefault'] == true) {
            final timestamp =
                macro['timestamp'] != null
                    ? DateTime.tryParse(macro['timestamp'])
                    : null;
            final lastModified =
                macro['lastModified'] != null
                    ? DateTime.tryParse(macro['lastModified'])
                    : null;
            final macroTime = timestamp ?? lastModified ?? DateTime(1970);

            if (mostRecentDefault == null ||
                (mostRecentTime != null && macroTime.isAfter(mostRecentTime))) {
              mostRecentDefault = macro;
              mostRecentTime = macroTime;
            }
          }
        }

        // If we found multiple defaults, ensure only one remains default
        if (mostRecentDefault != null) {
          bool madeChanges = false;

          // Set all other defaults to false
          for (int i = 0; i < macrosList.length; i++) {
            if (macrosList[i]['isDefault'] == true &&
                macrosList[i]['id'] != mostRecentDefault['id']) {
              macrosList[i]['isDefault'] = false;
              madeChanges = true;
            }
          }

          // Save back if changes were made
          if (madeChanges) {
            await prefs.setString(key, jsonEncode(macrosList));
            print(
              'Cleaned up SharedPreferences data - fixed multiple defaults',
            );

            // Update the dedicated default macro key
            await prefs.setString(defaultKey, jsonEncode(mostRecentDefault));
          }
        }
      }
    } catch (e) {
      print('Error cleaning up SharedPreferences data: $e');
      // Don't throw - this is a background operation that shouldn't affect the main flow
    }
  }

  Future<void> loadSavedMacros({String? userId}) async {
    if (_isDisposed) {
      print('Warning: Attempted to load macros with disposed ProfileNotifier');
      return;
    }

    try {
      final macros = await _repository.getSavedMacros(userId: userId);
      if (!_isDisposed) {
        state = AsyncData(_processMacroResults(macros));

        // Clean up SharedPreferences data to ensure consistency
        if (macros.isNotEmpty && userId != null) {
          await _cleanupSharedPreferencesData(userId);
        }
      }
    } catch (e) {
      print('Error loading saved macros: $e');
      if (!_isDisposed) {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }

  Future<void> deleteMacro(String id) async {
    await _repository.deleteMacro(id);

    // Get the current state data
    final currentData = state.valueOrNull;
    if (currentData != null) {
      // Check if we deleted a default macro
      final wasDefault = currentData.any((m) => m.id == id && m.isDefault);

      // If we deleted a default macro, we need to set a new default
      if (wasDefault) {
        // Get the user ID from any remaining macro
        final userId = currentData.isNotEmpty ? currentData.first.userId : null;
        if (userId != null) {
          // Find the most recent macro to set as default
          final remainingMacros = currentData.where((m) => m.id != id).toList();
          if (remainingMacros.isNotEmpty) {
            // Sort by timestamp (newest first)
            remainingMacros.sort((a, b) {
              final aTime =
                  a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            // Set the most recent as default
            if (remainingMacros.first.id != null) {
              await setDefaultMacro(remainingMacros.first.id!, userId);
              return; // loadSavedMacros will be called by setDefaultMacro
            }
          }
        }
      }
    }

    // Reload the macros
    await loadSavedMacros();
  }

  Future<void> setDefaultMacro(String id, String userId) async {
    if (_isDisposed) {
      print(
        'Warning: Attempted to set default macro with disposed ProfileNotifier',
      );
      return;
    }

    try {
      // First update the local state to ensure UI consistency
      if (!_isDisposed) {
        state = state.whenData((macros) {
          return macros.map((macro) {
            // Set the selected macro as default, all others as non-default
            if (macro.id == id) {
              return macro.copyWith(isDefault: true);
            } else if (macro.isDefault == true) {
              return macro.copyWith(isDefault: false);
            }
            return macro;
          }).toList();
        });
      }

      // Then update the repository
      await _repository.setDefaultMacro(id, userId: userId);

      // Ensure SharedPreferences data is consistent
      await _cleanupSharedPreferencesData(userId);

      // Finally reload to ensure consistency with database
      await loadSavedMacros(userId: userId);
    } catch (e) {
      print('Error setting default macro: $e');

      // Fallback: Try to update SharedPreferences directly
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        final key = 'saved_macros_$userId';
        final defaultKey = 'default_macro_$userId';

        // Get current data from SharedPreferences
        final savedMacrosJson = prefs.getString(key);
        if (savedMacrosJson == null || savedMacrosJson.isEmpty) return;

        final macrosList = jsonDecode(savedMacrosJson) as List<dynamic>;
        if (macrosList.isEmpty) return;

        // Update isDefault flags
        for (int i = 0; i < macrosList.length; i++) {
          macrosList[i]['isDefault'] = macrosList[i]['id'] == id;
        }

        // Save back to SharedPreferences
        await prefs.setString(key, jsonEncode(macrosList));
        print('Fallback: Updated default macro in SharedPreferences');

        // Also update the dedicated default macro key
        final defaultMacro = macrosList.firstWhere(
          (macro) => macro['id'] == id,
          orElse: () => macrosList.first,
        );

        if (defaultMacro != null) {
          await prefs.setString(
            'default_macro_$userId',
            jsonEncode(defaultMacro),
          );
          print(
            'Fallback: Updated dedicated default macro key in SharedPreferences',
          );
        }

        // Reload from SharedPreferences
        await loadSavedMacros(userId: userId);
      } catch (fallbackError) {
        print('Error in fallback default macro update: $fallbackError');
        rethrow;
      }
    }
  }

  Future<MacroResult?> getDefaultMacro({String? userId}) async {
    return await _repository.getDefaultMacro(userId: userId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Helper method to process macro results and remove duplicates
  List<MacroResult> _processMacroResults(List<MacroResult> macros) {
    if (macros.isEmpty) return [];

    // Use a map to track unique IDs
    final Map<String, MacroResult> uniqueMacros = {};
    MacroResult? defaultMacro;
    DateTime? latestDefaultTimestamp;

    // First pass: collect unique macros and find the latest default
    for (final macro in macros) {
      final id = macro.id;
      if (id == null) continue;

      // Store in unique map
      uniqueMacros[id] = macro;

      // Track the latest default macro
      if (macro.isDefault == true) {
        final macroTimestamp =
            macro.timestamp ?? macro.lastModified ?? DateTime(1970);
        if (defaultMacro == null ||
            (latestDefaultTimestamp != null &&
                macroTimestamp.isAfter(latestDefaultTimestamp))) {
          defaultMacro = macro;
          latestDefaultTimestamp = macroTimestamp;
        }
      }
    }

    // Second pass: ensure only one default
    if (defaultMacro != null) {
      // Reset all defaults
      for (final id in uniqueMacros.keys) {
        final macro = uniqueMacros[id]!;
        if (macro.isDefault == true && macro.id != defaultMacro!.id) {
          // Create a copy with isDefault set to false
          uniqueMacros[id] = macro.copyWith(isDefault: false);
        }
      }
    } else if (uniqueMacros.isNotEmpty) {
      // If no default was found, set the most recently modified one as default
      MacroResult mostRecent = uniqueMacros.values.first;
      DateTime? mostRecentTime =
          mostRecent.timestamp ?? mostRecent.lastModified;

      for (final macro in uniqueMacros.values) {
        final macroTime = macro.timestamp ?? macro.lastModified;
        if (mostRecentTime == null ||
            (macroTime != null && macroTime.isAfter(mostRecentTime))) {
          mostRecent = macro;
          mostRecentTime = macroTime;
        }
      }

      // Set the most recent as default
      uniqueMacros[mostRecent.id!] = mostRecent.copyWith(isDefault: true);
    }

    return uniqueMacros.values.toList();
  }

  Future<void> saveMacro(MacroResult macro, {String? userId}) async {
    if (_isDisposed) {
      print('Warning: Attempted to save macro with disposed ProfileNotifier');
      // Try to save directly to SharedPreferences as a fallback
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        final uid =
            userId ??
            ref.read(persistence.firebaseAuthProvider).currentUser?.uid;
        if (uid != null) {
          final key = 'saved_macros_$uid';
          final existingDataStr = prefs.getString(key);

          if (existingDataStr != null && existingDataStr.isNotEmpty) {
            final parsed = jsonDecode(existingDataStr);
            final List<Map<String, dynamic>> macrosList =
                List<Map<String, dynamic>>.from(
                  parsed.map((item) => Map<String, dynamic>.from(item)),
                );

            // Convert the macro to a map
            final macroMap = {
              'id':
                  macro.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'calories': macro.calories,
              'protein': macro.protein,
              'carbs': macro.carbs,
              'fat': macro.fat,
              'timestamp':
                  macro.timestamp?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'isDefault': macro.isDefault ?? false,
              'userId': uid,
              'name': macro.name ?? 'My Macros',
              'calculationType': macro.calculationType ?? 'custom',
              'lastModified': DateTime.now().toIso8601String(),
            };

            // Add or update the macro
            final existingIndex = macrosList.indexWhere(
              (m) => m['id'] == macroMap['id'],
            );
            if (existingIndex >= 0) {
              macrosList[existingIndex] = macroMap;
            } else {
              macrosList.add(macroMap);
            }

            // Save back to SharedPreferences
            await prefs.setString(key, jsonEncode(macrosList));
            print(
              'Fallback: Saved macro to SharedPreferences after ProfileNotifier disposal',
            );
          }
        }
      } catch (e) {
        print('Error in fallback macro save: $e');
      }
      return;
    }

    try {
      await _repository.saveMacro(macro, userId: userId);
      await loadSavedMacros(userId: userId);
    } catch (e) {
      print('Error saving macro: $e');
      rethrow;
    }
  }
}
