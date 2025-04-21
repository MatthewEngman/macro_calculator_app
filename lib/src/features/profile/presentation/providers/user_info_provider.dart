// user_info_provider.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../domain/entities/user_info.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as auth;
import '../../../../core/persistence/repository_providers.dart';
import '../../../../core/persistence/onboarding_provider.dart';

final userInfoProvider = FutureProvider<List<UserInfo>>((ref) async {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  if (!onboardingComplete) return [];
  final syncService = await ref.watch(firestoreSyncServiceProvider.future);
  final authProvider = ref.watch(auth.firebaseAuthProvider);
  final userId = authProvider.currentUser?.uid;
  if (userId == null) return [];
  return await syncService.getSavedUserInfos(userId);
});

class UserInfoNotifier extends StateNotifier<AsyncValue<List<UserInfo>>> {
  final FirestoreSyncService _syncService;
  final firebase_auth.FirebaseAuth _auth;

  UserInfoNotifier(this._syncService, this._auth)
    : super(const AsyncValue.loading()) {
    loadSavedUserInfos();
  }

  Future<void> setDefaultMacro(String macroId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userInfos = await _syncService.getSavedUserInfos(userId);

    for (final user in userInfos) {
      final shouldBeDefault = user.id == macroId;
      if (user.isDefault != shouldBeDefault) {
        await _syncService.saveUserInfo(
          userId,
          user.copyWith(isDefault: shouldBeDefault),
        );
      }
    }

    await loadSavedUserInfos();
  }

  Future<List<UserInfo>> loadSavedUserInfos() async {
    state = const AsyncValue.loading();
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return [];
      }

      final userInfos = await _syncService.getSavedUserInfos(userId);
      state = AsyncValue.data(userInfos);
      return userInfos;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
    await _syncService.saveUserInfo(userId, userInfo);
    loadSavedUserInfos();
  }

  Future<void> deleteUserInfo(String userId, String id) async {
    await _syncService.deleteUserInfo(userId, id);
    loadSavedUserInfos();
  }

  Future<void> setDefaultUserInfo(String userId, String id) async {
    await _syncService.setDefaultUserInfo(userId, id);
    await loadSavedUserInfos();
  }

  Future<UserInfo?> getDefaultUserInfo() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return await _syncService.getDefaultUserInfo(userId);
  }

  // Method to trigger manual sync
  Future<void> syncUserInfos() async {
    await _syncService.processSyncQueue();
    await loadSavedUserInfos();
  }
}
