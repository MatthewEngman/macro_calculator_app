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
    final newUserInfo = userInfo.copyWith(id: id);

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
        await UserDB.updateUser(newUserInfo);
      } else {
        await UserDB.insertUser(newUserInfo, _requiredUserId);
      }
    }
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    final userInfo = await UserDB.getUserById(id);
    if (userInfo == null) return;

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
    return await UserDB.getDefaultUser(firebaseUserId: _requiredUserId);
  }
}
