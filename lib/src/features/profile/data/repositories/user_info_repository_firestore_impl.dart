import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../domain/repositories/user_info_respository.dart';
import '../../domain/entities/user_info.dart';

class UserInfoRepositoryFirestoreImpl implements UserInfoRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final FirestoreSyncService _syncService = FirestoreSyncService();
  final String _collection = 'user_infos';

  UserInfoRepositoryFirestoreImpl(this._firestore, this._auth);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Helper method to get the user-specific collection path
  String get _userCollection => 'users/$_userId/$_collection';

  @override
  Future<List<UserInfo>> getSavedUserInfos() async {
    // Check if user is authenticated
    if (_userId == null) {
      return [];
    }

    // Use sync service instead of direct Firestore access
    return await _syncService.getSavedUserInfos(_userId!);
  }

  @override
  Future<void> saveUserInfo(UserInfo userInfo) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final userInfos = await getSavedUserInfos();
    final isFirstUserInfo = userInfos.isEmpty;

    final newUserInfo = userInfo.copyWith(
      id: userInfo.id,
      isDefault: userInfo.isDefault || isFirstUserInfo,
    );

    // Use sync service instead of direct Firestore access
    await _syncService.saveUserInfo(_userId!, newUserInfo);
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final userInfos = await getSavedUserInfos();
    final userInfo = userInfos.firstWhere(
      (info) => info.id == id,
      orElse: () => throw Exception('User info not found'),
    );

    if (userInfo.isDefault) {
      return; // Don't delete if is default
    }

    // Use sync service instead of direct Firestore access
    await _syncService.deleteUserInfo(_userId!, id);
  }

  @override
  Future<void> setDefaultUserInfo(String id) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Use sync service instead of direct Firestore access
    await _syncService.setDefaultUserInfo(_userId!, id);
  }

  @override
  Future<UserInfo?> getDefaultUserInfo() async {
    // Check if user is authenticated
    if (_userId == null) {
      return null;
    }

    // Use sync service instead of direct Firestore access
    return await _syncService.getDefaultUserInfo(_userId!);
  }
}
