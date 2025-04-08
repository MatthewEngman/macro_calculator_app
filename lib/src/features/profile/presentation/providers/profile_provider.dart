import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../calculator/domain/entities/macro_result.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<List<MacroResult>>>((
      ref,
    ) {
      return ProfileNotifier(ref.watch(profileRepositoryProvider));
    });

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('Implement in main.dart');
});

// Provider for accessing the default macro
final defaultMacroProvider = FutureProvider<MacroResult?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getDefaultMacro();
});

class ProfileNotifier extends StateNotifier<AsyncValue<List<MacroResult>>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSavedMacros();
  }

  Future<void> loadSavedMacros() async {
    state = const AsyncValue.loading();
    try {
      final macros = await _repository.getSavedMacros();
      state = AsyncValue.data(macros);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveMacro(MacroResult result) async {
    await _repository.saveMacro(result);
    loadSavedMacros();
  }

  Future<void> deleteMacro(String id) async {
    await _repository.deleteMacro(id);
    loadSavedMacros();
  }

  Future<void> setDefaultMacro(String id) async {
    await _repository.setDefaultMacro(id);
    await loadSavedMacros();
  }

  Future<MacroResult?> getDefaultMacro() async {
    return await _repository.getDefaultMacro();
  }
}
