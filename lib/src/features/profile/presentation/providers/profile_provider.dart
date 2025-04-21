import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../calculator/domain/entities/macro_result.dart';
import '../../../../core/persistence/onboarding_provider.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as persistence;

final macroListProvider = FutureProvider<List<MacroResult>>((ref) async {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  if (!onboardingComplete) return [];
  final repository = await ref.watch(
    persistence.profileRepositorySyncProvider.future,
  );
  return await repository.getSavedMacros();
});

final defaultMacroProvider = FutureProvider<MacroResult?>((ref) async {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  if (!onboardingComplete) {
    print('Default Macro Provider: Onboarding not complete, returning null');
    return null;
  }
  
  print('Default Macro Provider: Getting repository...');
  final repository = await ref.watch(
    persistence.profileRepositorySyncProvider.future,
  );
  
  print('Default Macro Provider: Retrieving default macro...');
  final defaultMacro = await repository.getDefaultMacro();
  
  if (defaultMacro != null) {
    print('Default Macro Provider: Found default macro with ID: ${defaultMacro.id}');
  } else {
    print('Default Macro Provider: No default macro found');
  }
  
  return defaultMacro;
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

  Future<void> loadSavedMacros() async {
    state = const AsyncValue.loading();
    try {
      // _repository should be initialized by _initialize before this is called
      final macros = await _repository.getSavedMacros();
      state = AsyncValue.data(macros);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      print('Error loading saved macros: $e');
    }
  }

  Future<void> saveMacro(MacroResult result) async {
    await _repository.saveMacro(result);
    await _initialize();
  }

  Future<void> deleteMacro(String id) async {
    await _repository.deleteMacro(id);
    await _initialize();
  }

  Future<void> setDefaultMacro(String id) async {
    await _repository.setDefaultMacro(id);
    await _initialize();
  }

  Future<MacroResult?> getDefaultMacro() async {
    return await _repository.getDefaultMacro();
  }
}
