// lib/src/features/profile/data/repositories/user_info_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user_info.dart';
import '../../domain/repositories/user_info_respository.dart';
import 'user_db.dart';

class UserInfoRepositorySQLiteImpl implements UserInfoRepository {
  final firebase_auth.FirebaseAuth _auth;

  UserInfoRepositorySQLiteImpl(this._auth);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;
  String get _requiredUserId {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User must be logged in to perform this operation');
    }
    return userId;
  }

  @override
  Future<List<UserInfo>> getSavedUserInfos() async {
    return await UserDB.getAllUsers(firebaseUserId: _requiredUserId);
  }

  @override
  Future<void> saveUserInfo(UserInfo userInfo) async {
    final id = userInfo.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final newUserInfo = userInfo.copyWith(
      id: id,
      lastModified: userInfo.lastModified ?? now,
    );

    // If this is the first user info, set it as default
    final allUserInfos = await getSavedUserInfos();
    final isFirstUserInfo = allUserInfos.isEmpty;

    if (isFirstUserInfo) {
      await UserDB.insertUser(
        newUserInfo.copyWith(isDefault: true),
        _requiredUserId,
      );
    } else {
      // Check if we're updating an existing user info
      final existingUserInfo = await UserDB.getUserById(id);

      if (existingUserInfo != null) {
        // Use timestamp-based conflict resolution
        await UserDB.updateUser(newUserInfo, _requiredUserId);
      } else {
        await UserDB.insertUser(newUserInfo, _requiredUserId);
      }
    }
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    final userInfo = await UserDB.getUserById(id);
    if (userInfo == null) return;

    // Don't delete if it's the default user info and it's the only one
    if (userInfo.isDefault) {
      final allUserInfos = await getSavedUserInfos();
      if (allUserInfos.length <= 1) {
        return; // Don't delete the only user info
      }
    }

    await UserDB.deleteUser(id);

    // If the deleted user info was the default one, set a new default
    if (userInfo.isDefault) {
      final allUserInfos = await getSavedUserInfos();
      if (allUserInfos.isNotEmpty) {
        await setDefaultUserInfo(allUserInfos.first.id!);
      }
    }
  }

  @override
  Future<void> setDefaultUserInfo(String id) async {
    await UserDB.setDefaultUser(id, firebaseUserId: _requiredUserId);
  }

  @override
  Future<UserInfo?> getDefaultUserInfo() async {
    final defaultUser = await UserDB.getDefaultUser(
      firebaseUserId: _requiredUserId,
    );

    // If no default user is found, try to get the first user and set it as default
    if (defaultUser == null) {
      final allUsers = await getSavedUserInfos();
      if (allUsers.isNotEmpty) {
        // Set the first user as default
        await setDefaultUserInfo(allUsers.first.id!);
        return allUsers.first;
      }
    }

    return defaultUser;
  }
}
