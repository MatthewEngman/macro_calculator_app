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

  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const AsyncValue.loading();
    try {
      _repository = await ref.read(
        persistence.profileRepositorySyncProvider.future,
      );
      await loadSavedMacros();
      final macros = await _repository.getSavedMacros();
      state = AsyncValue.data(macros);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadSavedMacros({String? userId}) async {
    state = const AsyncValue.loading();
    try {
      // _repository should be initialized by _initialize before this is called
      final macros = await _repository.getSavedMacros(userId: userId);
      state = AsyncValue.data(macros);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      print('Error loading saved macros: $e');
    }
  }

  Future<void> saveMacro(MacroResult result, {String? userId}) async {
    await _repository.saveMacro(result, userId: userId);
    await _initialize();
  }

  Future<void> deleteMacro(String id) async {
    await _repository.deleteMacro(id);
    await _initialize();
  }

  Future<void> setDefaultMacro(String id, String userId) async {
    await _repository.setDefaultMacro(id, userId: userId);
    await _initialize();
  }

  Future<MacroResult?> getDefaultMacro({String? userId}) async {
    return await _repository.getDefaultMacro(userId: userId);
  }
}
