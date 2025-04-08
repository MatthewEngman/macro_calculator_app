import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_info.dart';
import '../../domain/repositories/user_info_respository.dart';
import '../../data/repositories/user_info_repository_impl.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

final userInfoRepositoryProvider = Provider<UserInfoRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserInfoRepositoryImpl(prefs);
});

class UserInfoNotifier extends StateNotifier<AsyncValue<List<UserInfo>>> {
  final UserInfoRepository _repository;

  UserInfoNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSavedUserInfos();
  }

  Future<void> loadSavedUserInfos() async {
    state = const AsyncValue.loading();
    try {
      final userInfos = await _repository.getSavedUserInfos();
      state = AsyncValue.data(userInfos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveUserInfo(UserInfo userInfo) async {
    await _repository.saveUserInfo(userInfo);
    loadSavedUserInfos();
  }

  Future<void> deleteUserInfo(String id) async {
    await _repository.deleteUserInfo(id);
    loadSavedUserInfos();
  }

  Future<void> setDefaultUserInfo(String id) async {
    await _repository.setDefaultUserInfo(id);
    await loadSavedUserInfos();
  }

  Future<UserInfo?> getDefaultUserInfo() async {
    return await _repository.getDefaultUserInfo();
  }
}

final userInfoProvider =
    StateNotifierProvider<UserInfoNotifier, AsyncValue<List<UserInfo>>>((ref) {
      final repository = ref.watch(userInfoRepositoryProvider);
      return UserInfoNotifier(repository);
    });
