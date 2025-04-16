// user_info_provider.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../domain/entities/user_info.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as auth;
import '../../../../core/persistence/repository_providers.dart';

// Provider for Firestore instance
final userInfoProvider =
    StateNotifierProvider<UserInfoNotifier, AsyncValue<List<UserInfo>>>((ref) {
      final syncService = ref.watch(firestoreSyncServiceProvider);
      final authProvider = ref.watch(auth.firebaseAuthProvider);
      return UserInfoNotifier(syncService, authProvider);
    });

class UserInfoNotifier extends StateNotifier<AsyncValue<List<UserInfo>>> {
  final FirestoreSyncService _syncService;
  final firebase_auth.FirebaseAuth _auth;

  UserInfoNotifier(this._syncService, this._auth)
    : super(const AsyncValue.loading()) {
    loadSavedUserInfos();
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
