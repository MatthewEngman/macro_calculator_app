import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_info.dart';
import '../../domain/repositories/user_info_respository.dart';
import '../../data/repositories/user_info_repository_firestore_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userInfoRepositoryProvider = Provider<UserInfoRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return UserInfoRepositoryFirestoreImpl(firestore, auth);
});

class UserInfoNotifier extends StateNotifier<AsyncValue<List<UserInfo>>> {
  final UserInfoRepository _repository;

  UserInfoNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSavedUserInfos();
  }

  Future<List<UserInfo>> loadSavedUserInfos() async {
    state = const AsyncValue.loading();
    try {
      final userInfos = await _repository.getSavedUserInfos();
      state = AsyncValue.data(userInfos);
      return userInfos;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
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
